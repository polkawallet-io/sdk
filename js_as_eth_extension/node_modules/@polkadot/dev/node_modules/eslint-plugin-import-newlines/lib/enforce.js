const SPEC_IMPORT = 'ImportSpecifier';
const SPEC_DEFAULT_IMPORT = 'ImportDefaultSpecifier';

const applyAlias = (currentNode) => {
  const localName = currentNode.local.name;
  if (!currentNode.imported) {
    return localName;
  }
  const importedName = currentNode.imported.name;
  return importedName !== localName
    ? `${importedName} as ${localName}`
    : importedName;
};

const fixer = (node, semi, spacer = '\n') => (eslintFixer) => {
  let defaultImport = '';
  const objectImports = [];
  const { specifiers, importKind } = node;
  specifiers.forEach((currentNode) => {
    switch (currentNode.type) {
      case SPEC_DEFAULT_IMPORT:
        defaultImport = applyAlias(currentNode);
        break;
      case SPEC_IMPORT:
        objectImports.push(applyAlias(currentNode));
        break;
      default:
        break;
    }
  });
  const defaultImportValue = defaultImport.length > 0
    ? objectImports.length > 0 ? `${defaultImport}, ` : defaultImport
    : defaultImport;
  const objectImportsValue = objectImports.length > 0
    ? `{${spacer}${objectImports.join(`,${spacer}`)}${spacer}}`
    : '';
  const importKeyword = importKind === 'type' ? 'import type' : 'import';
  const newValue = `${importKeyword} ${defaultImportValue}${objectImportsValue} from ${node.source.raw}${semi ? ';' : ''}`;
  return eslintFixer.replaceText(node, newValue);
};

const DEFAULT_ITEMS = 4;
const MIN_ITEMS = 0;
const DEFAULT_MAX_LENGTH = Infinity;
const MIN_MAX_LENGTH = 17;
const DEFAULT_SEMICOLON = true;

module.exports = {
  meta: {
    type: 'layout',
    docs: {
      description: 'enforce multiple lines for import statements past a certain number of items',
      category: 'Stylistic Issues',
      url: 'https://github.com/SeinopSys/eslint-plugin-import-newlines',
    },
    fixable: 'whitespace',
    schema: {
      oneOf: [
        {
          type: 'array',
          minItems: 1,
          maxItems: 1,
          items: {
            type: 'object',
            properties: {
              items: {
                type: 'number',
                minimum: 1,
              },
              'max-len': {
                type: 'number',
                minimum: 17,
              },
              semi: {
                type: 'boolean',
              },
            },
          },
        },
        {
          type: 'array',
          minItems: 0,
          maxItems: 2,
          items: {
            type: 'number',
          },
        },
      ],
    },
    messages: {
      mustSplitMany: 'Imports must be broken into multiple lines if there are more than {{maxItems}} elements.',
      mustSplitLong: 'Imports must be broken into multiple lines if the line length exceeds {{maxLineLength}} characters, saw {{lineLength}}.',
      mustNotSplit: 'Imports must not be broken into multiple lines if there are {{maxItems}} or less elements.',
      noBlankBetween: 'Import lines cannot have more than one blank line between them.',
      limitLineCount: 'Import lines must have one element per line. (Expected import to span {{expectedLineCount}} lines, saw {{importLineCount}})',
    },
  },
  create(context) {
    let maxItems;
    let maxLineLength;
    let includeSemi;
    if (typeof context.options[0] === 'object') {
      const optionsObj = context.options[0];
      maxItems = typeof optionsObj.items !== 'undefined' ? optionsObj.items : DEFAULT_ITEMS;
      maxLineLength = typeof optionsObj['max-len'] !== 'undefined' ? optionsObj['max-len'] : DEFAULT_MAX_LENGTH;
      includeSemi = typeof optionsObj.semi !== 'undefined' ? optionsObj.semi : DEFAULT_SEMICOLON;
    } else {
      [
        maxItems = DEFAULT_ITEMS,
        maxLineLength = DEFAULT_MAX_LENGTH,
      ] = context.options;
    }
    if (maxItems < MIN_ITEMS) {
      throw new Error(`Minimum items must not be less than ${MIN_MAX_LENGTH}`);
    }
    if (maxLineLength < MIN_MAX_LENGTH) {
      throw new Error(`Maximum line length must not be less than ${MIN_MAX_LENGTH}`);
    }
    return {
      ImportDeclaration(node) {
        const { specifiers } = node;

        let blankLinesReported = false;
        const importLineCount = 1 + (node.loc.end.line - node.loc.start.line);
        const importedItems = specifiers.reduce((a, c) => a + (c.type === SPEC_IMPORT ? 1 : 0), 0);

        specifiers.slice(1).forEach((currentItem, index) => {
          const previousItem = specifiers[index];
          const previousEndLine = previousItem.loc.end.line;
          const currentStartLine = currentItem.loc.start.line;
          const lineDifference = currentStartLine - previousEndLine;
          if (!blankLinesReported && lineDifference > 1) {
            context.report({
              node,
              messageId: 'noBlankBetween',
              fix: fixer(node, includeSemi),
            });
            blankLinesReported = true;
          }
        });

        if (!blankLinesReported) {
          const singleLine = importLineCount === 1;
          if (singleLine) {
            const line = context.getSourceCode().getText(node);
            if (line.length > maxLineLength) {
              context.report({
                node,
                messageId: 'mustSplitLong',
                data: { maxLineLength, lineLength: line.length },
                fix: fixer(node, includeSemi),
              });
              return;
            }
            if (importedItems > maxItems) {
              context.report({
                node,
                messageId: 'mustSplitMany',
                data: { maxItems },
                fix: fixer(node, includeSemi),
              });
            }
            return;
          }

          // One item per line + line with import + line with from
          const expectedLineCount = importedItems + 2;
          if (importLineCount !== expectedLineCount) {
            context.report({
              node,
              messageId: 'limitLineCount',
              data: { expectedLineCount, importLineCount },
              fix: fixer(node, includeSemi),
            });
            return;
          }

          if (importedItems <= maxItems) {
            let fixedValue;
            const fix = fixer(node, includeSemi, ' ');
            fix({
              replaceText: (_node, value) => {
                fixedValue = value;
              },
            });
            // Only enforce this rule if fixing it would not cause going over the line length limit
            if (fixedValue.length <= maxLineLength) {
              context.report({
                node,
                messageId: 'mustNotSplit',
                data: { maxItems },
                fix,
              });
            }
          }
        }
      },
    };
  },
};
