import type { NextPage } from "next";
import { Avatar, Heading } from "@chakra-ui/react";
import gravatarUrl from "gravatar-url";

const Header: NextPage = (props) => {
  return (
    <>
      <Heading ml="8" size="md" fontWeight="semibold" color="cyan.400">
        Takeru O'oyama
      </Heading>
      <Avatar
        size={"md"}
        src={gravatarUrl("tqer39@gmail.com", { size: 100 })}
      />
    </>
  );
};

export default Header;
