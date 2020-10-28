import gleam/pgo
import gleam/atom

pub fn query(sql, arguments) {
  pgo.query(atom_("default"), sql, arguments)
}

fn atom_(atom_name) {
  atom.create_from_string(atom_name)
}
