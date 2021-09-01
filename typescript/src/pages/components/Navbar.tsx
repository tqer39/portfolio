import type { NextPage } from "next";
import { Avatar, Heading } from "@chakra-ui/react";
import { useColorMode } from "@chakra-ui/color-mode";
import { IconButton } from "@chakra-ui/button";
import { FaSun, FaMoon, FaGithub } from "react-icons/fa";
import gravatarUrl from "gravatar-url";

const Header: NextPage = (props) => {
  const { colorMode, toggleColorMode } = useColorMode();
  const isDark = colorMode === "dark";

  return (
    <>
      <Heading ml="8" size="md" fontWeight="semibold" color="cyan.400">
        Takeru O'oyama
      </Heading>
      <Avatar
        size={"md"}
        src={gravatarUrl("tqer39@gmail.com", { size: 100 })}
      />
      <IconButton
        ml={2}
        aria-label=""
        icon={<FaGithub />}
        isRound={true}
      ></IconButton>
      <IconButton
        ml={8}
        aria-label=""
        icon={isDark ? <FaSun /> : <FaMoon />}
        isRound={true}
        onClick={toggleColorMode}
      ></IconButton>
    </>
  );
};

export default Header;
