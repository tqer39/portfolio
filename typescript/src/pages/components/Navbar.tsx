// import React from "react";
import type { NextPage } from "next";
import { Avatar } from "@chakra-ui/react";
import gravatarUrl from "gravatar-url";

const Header: NextPage = (props) => {
  return (
    <>
      <Avatar
        size={"md"}
        src={gravatarUrl("tqer39@gmail.com", { size: 100 })}
      />
    </>
  );
};

export default Header;
