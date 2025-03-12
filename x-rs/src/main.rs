use std::{env, io::Write, process::exit};

use tree_sitter_cli::highlight::Theme;
use tree_sitter_highlight::{Highlight, Highlighter, HtmlRenderer};
use tree_sitter_loader::{Config, Loader};

use anyhow::anyhow;

pub fn highlight_adapter(code: &str, scope: &str) -> anyhow::Result<String> {
    let parser_directory = env::current_dir()?.join("parsers");
    let theme_path = env::current_dir()?.join("theme.json");

    let theme: Theme = Theme::load(&theme_path)?;

    // The loader is used to load parsers
    let loader = {
        let mut loader = Loader::new()?;
        let config = {
            let parser_directories = vec![parser_directory];
            Config { parser_directories }
        };
        loader.find_all_languages(&config)?;
        loader.configure_highlights(&theme.highlight_names);
        loader
    };

    // Retrieve the highlight config for the given language scope
    let config = loader
        .language_configuration_for_scope(scope)?
        .and_then(|(language, config)| config.highlight_config(language, None).ok())
        .flatten()
        .ok_or(anyhow!("scope `{}` not found highlight", scope))?;

    let code = code.as_bytes();

    // Highlight the code
    let mut highlighter = Highlighter::new();
    let highlights = highlighter.highlight(config, code, None, |_| None)?;

    // Render and return the highlighted code as an HTML snippet
    let get_style_css = |h: Highlight, html: &mut Vec<u8>| {
        let css = theme
            .styles
            .get(h.0)
            .and_then(|x| x.css.as_ref())
            .expect(format!("scope: {}", scope).as_str())
            .as_bytes();
        html.write_all(b"style=\"").unwrap();
        html.write_all(css).unwrap();
        html.write_all(b"\"").unwrap();
    };
    let mut renderer = HtmlRenderer::new();
    renderer.render(highlights, code, &get_style_css)?;
    Ok(renderer.lines().collect())
}

fn main() -> anyhow::Result<()> {
    let mut args = env::args();
    args.next();
    let code = args.next().ok_or(anyhow!("need param `code`"))?;
    let lang = args.next().ok_or(anyhow!("need param `lang`"))?;

    match highlight_adapter(&code, &format!("source.{}", lang)) {
        Ok(x) => println!("{}", x),
        Err(e) => {
            eprintln!("error: {}", e);
            exit(1);
        }
    }

    Ok(())
}
