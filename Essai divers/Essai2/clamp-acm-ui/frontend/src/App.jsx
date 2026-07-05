import { BrowserRouter } from "react-router-dom";
import Header from "./components/Common/Header";
import Sidebar from "./components/Common/Sidebar";
import Footer from "./components/Common/Footer";
import AppRoutes from "./routes";

function App() {
  return (
    <BrowserRouter>
      <Header />
      <Sidebar />
      <AppRoutes />
      <Footer />
    </BrowserRouter>
  );
}

export default App;