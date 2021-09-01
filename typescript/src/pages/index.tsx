import type { NextPage } from "next";
import { ChakraProvider } from "@chakra-ui/react";
import Navbar from "./components/Navbar";

const Home: NextPage = () => {
  return (
    <ChakraProvider>
      <Navbar />
      <h1>About</h1>
      Profile Image.
      <hr />
      <h1>Skill</h1>
      <hr />
      <h1>Profile</h1>
      <footer>copyright</footer>
    </ChakraProvider>
  );
};

export default Home;
