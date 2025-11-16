import { Link } from "react-router-dom";

export default function Navbar() {
  return (
    <div className="navbar">
      <div>Educational App</div>
      <div>
        <Link to="/">Login</Link>
        <Link to="/signup">Sign Up</Link>
        <Link to="/dashboard">Dashboard</Link>
      </div>
    </div>
  );
}
