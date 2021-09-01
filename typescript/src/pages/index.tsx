import type { NextPage } from "next";
import { ChakraProvider } from "@chakra-ui/react";
import Layout from "./components/Layout";

const Home: NextPage = () => {
  return (
    <ChakraProvider>
      <Layout />
    </ChakraProvider>
  );
};

export default Home;
