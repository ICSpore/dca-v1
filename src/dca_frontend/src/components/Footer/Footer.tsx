import React from "react";
import "./Footer.css";
import Logo from "../Logo/Logo";
import gitHubIcon from "../../images/github-mark-white.svg";
import xLogo from "../../images/x-logo.svg";
import openChatLogo from "../../images/spinner.svg";
import telegramLogo from "../../images/Telegram_logo.svg";

const Footer: React.FC = () => {
    return (
        <footer className="footer">
            <ul className="footer__container">
                <li className="footer__column">
                    <Logo />
                    <p className="footer__description">Decentralized non-custodial payment automation protocol.</p>
                </li>
                <li className="footer__column">
                    <h4 className="footer__column-title">Docs</h4>
                    <ul className="footer__link-list">
                        <li className="footer__link">
                            <a href="https://github.com/ICSpore/dca-v1" target="_blank" className="footer__link">
                                <img className="footer__link-icon" src={gitHubIcon} alt="GitHub icon" />
                                <span className="footer__link-description">GitHub</span>
                            </a>
                        </li>
                    </ul>
                </li>
                <li className="footer__column">
                    <h4 className="footer__column-title">Folow us</h4>
                    <ul className="footer__link-list">
                        <li className="footer__link">
                            <a
                                href="https://oc.app/community/ijf7l-liaaa-aaaaf-bm4ya-cai/channel/7099643226996241201990501345632831172/"
                                className="footer__link"
                                target="_blank"
                            >
                                <img className="footer__link-icon" src={openChatLogo} alt="OpenChat Icon" />
                                <span className="footer__link-description">OpenChat</span>
                            </a>
                        </li>
                        <li className="footer__link">
                            <a href="https://t.me/+1UAHaPzbAUg5N2Fi" target="_blank" className="footer__link">
                                <img className="footer__link-icon" src={telegramLogo} alt="Telegram Icon" />
                                <span className="footer__link-description">Telegram</span>
                            </a>
                        </li>
                        <li className="footer__link">
                            <a href="https://x.com/icspore" target="_blank" className="footer__link">
                                <img className="footer__link-icon" src={xLogo} alt="Twitter/X icon" />
                                <span className="footer__link-description">x.com</span>
                            </a>
                        </li>
                    </ul>
                </li>
            </ul>
        </footer>
    );
};

export default Footer;
