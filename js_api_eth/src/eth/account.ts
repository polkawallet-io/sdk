import Jazzicon from "@metamask/jazzicon";
/**
 * Get svg icons of addresses.
 */
async function genIcons(addresses: string[]) {
  return addresses.map((address) => {
    const icon = Jazzicon(16, parseInt(address.slice(2, 10), 16));
    return [address, icon.innerHTML];
  });
}

export default {
  genIcons,
};
