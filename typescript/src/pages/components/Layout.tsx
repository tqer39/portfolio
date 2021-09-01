import type { NextPage } from "next";
import { VStack } from "@chakra-ui/layout";
import Navbar from "./Navbar";

const Layout: NextPage = () => {
  return (
    <VStack>
      <Navbar />
      <h1>About</h1>
      Profile Image.
      <hr />
      <h1>Skill</h1>
      <hr />
      <h1>Profile</h1>
      <footer>copyright</footer>
    </VStack>
  );
};

export default Layout;
