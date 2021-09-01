import type { NextPage } from "next";
import { ChakraProvider, ColorModeScript } from "@chakra-ui/react";
import Layout from "./components/Layout";

const Home: NextPage = () => {
  return (
    <ChakraProvider>
      <ColorModeScript initialColorMode="light"></ColorModeScript>
      <Layout />
    </ChakraProvider>
  );
};

export default Home;
