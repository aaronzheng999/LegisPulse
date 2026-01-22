import BillForm from './pages/BillForm';
import Dashboard from './pages/Dashboard';
import EmailLists from './pages/EmailLists';
import Settings from './pages/Settings';
import TrackedBills from './pages/TrackedBills';
import TwitterFeed from './pages/TwitterFeed';
import TwitterSetup from './pages/TwitterSetup';
import __Layout from './Layout.jsx';


export const PAGES = {
    "BillForm": BillForm,
    "Dashboard": Dashboard,
    "EmailLists": EmailLists,
    "Settings": Settings,
    "TrackedBills": TrackedBills,
    "TwitterFeed": TwitterFeed,
    "TwitterSetup": TwitterSetup,
}

export const pagesConfig = {
    mainPage: "Dashboard",
    Pages: PAGES,
    Layout: __Layout,
};