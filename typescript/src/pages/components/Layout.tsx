import type { NextPage } from "next";
import Navbar from "./Navbar";

const Layout: NextPage = () => {
  return (
    <>
      <Navbar />
      <h1>About</h1>
      Profile Image.
      <hr />
      <h1>Skill</h1>
      <hr />
      <h1>Profile</h1>
      <footer>copyright</footer>
    </>
  );
};

export default Layout;
