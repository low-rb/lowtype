# frozen_string_literal: true

module Low
  # Opt-in, per class: `ractor_safe!` in the class body switches Redefiner's codegen
  # from define_method blocks (fast, but Proc-backed methods can't be called from a
  # Ractor other than the one that defined them) to class_eval'd source strings (real
  # methods, callable from any Ractor once Lowkey.make_shareable! has been called).
  # Most classes never run inside a worker Ractor and shouldn't pay for the per-call
  # registry lookup the ractor-safe path requires -- see Redefiner.redefine.
  module RactorSafety
    def ractor_safe!
      @ractor_safe = true
    end

    def ractor_safe?
      @ractor_safe || false
    end
  end
end
