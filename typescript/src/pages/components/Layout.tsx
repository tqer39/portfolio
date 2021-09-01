import type { NextPage } from "next";
import { Flex } from "@chakra-ui/react";
import { VStack } from "@chakra-ui/layout";
import Navbar from "./Navbar";

const Layout: NextPage = () => {
  return (
    <VStack p={5}>
      <Flex w="100%">
        <Navbar />
        <h1>About</h1>
        Profile Image.
        <hr />
        <h1>Skill</h1>
        <hr />
        <h1>Profile</h1>
        <footer>copyright</footer>
      </Flex>
    </VStack>
  );
};

export default Layout;
