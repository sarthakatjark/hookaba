extension BoolOp on bool {
  bool get isTrue => this;
  bool get isFalse => !this;
  bool get not => !this;
  bool toggle() => !this;
}

