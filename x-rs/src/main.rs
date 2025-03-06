use std::{env, io::Write};

use tree_sitter_cli::highlight::Theme;
use tree_sitter_highlight::{Highlight, Highlighter, HtmlRenderer};
use tree_sitter_loader::{Config, Loader};

pub fn highlight_adapter(code: &str, scope: &str) -> String {
    let parser_directory = env::current_dir().unwrap().join("parsers");
    let theme_path = env::current_dir().unwrap().join("theme.json");

    let theme: Theme = Theme::load(&theme_path).unwrap();

    // The loader is used to load parsers
    let loader = {
        let mut loader = Loader::new().unwrap();
        let config = {
            let parser_directories = vec![parser_directory];
            Config { parser_directories }
        };
        loader.find_all_languages(&config).unwrap();
        loader.configure_highlights(&theme.highlight_names);
        loader
    };

    // Retrieve the highlight config for the given language scope
    let config = loader
        .language_configuration_for_scope(scope)
        .unwrap()
        .and_then(|(language, config)| config.highlight_config(language, None).ok())
        .unwrap()
        .unwrap();

    let code = code.as_bytes();

    // Highlight the code
    let mut highlighter = Highlighter::new();
    let highlights = highlighter.highlight(config, code, None, |_| None).unwrap();

    // Render and return the highlighted code as an HTML snippet
    let get_style_css = |h: Highlight, html: &mut Vec<u8>| {
        let css = theme.styles[h.0].css.as_ref().unwrap().as_bytes();
        html.write_all(b"style=\"").unwrap();
        html.write_all(css).unwrap();
        html.write_all(b"\"").unwrap();
    };
    let mut renderer = HtmlRenderer::new();
    renderer.render(highlights, code, &get_style_css).unwrap();
    renderer.lines().collect()
}

fn main() {
    let mut args = env::args();
    args.next();
    let code = args.next().unwrap();
    let lang = args.next().unwrap();

    let x = highlight_adapter(&code, &format!("source.{}", lang));
    println!("{}", x);
}
