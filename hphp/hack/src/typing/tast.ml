(*
 * Copyright (c) 2017, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the "hack" directory of this source tree.
 *
 *)

include Aast_defs

[@@@warning "-33"]

open Hh_prelude

[@@@warning "+33"]

(* This is the current notion of type in the typed AST.
 * In future we might want to reconsider this and define a new representation
 * that omits type inference artefacts such as type variables and lambda
 * identifiers.
 *)
type ty = Typing_defs.locl_ty

type possibly_enforced_ty = Typing_defs.locl_possibly_enforced_ty

type decl_ty = Typing_defs.decl_ty

type val_kind = Typing_defs.val_kind

let pp_ty = Typing_defs.pp_locl_ty

let show_ty = Typing_defs.show_locl_ty

let pp_decl_ty = Typing_defs.pp_decl_ty

let show_decl_ty = Typing_defs.show_decl_ty

let pp_ifc_fun_decl fmt d = Typing_defs.pp_ifc_fun_decl fmt d

(* Contains information about a specific function that we
    a) want to make available to TAST checks
    b) isn't otherwise (space-efficiently) present in the saved typing env *)
type fun_tast_info = {
  has_implicit_return: bool;
      (** True if there are leaves of the function's imaginary CFG without a return statement *)
  named_body_is_unsafe: bool;  (** Result of {!Nast.named_body_is_unsafe} *)
}
[@@deriving show]

type saved_env = {
  tcopt: TypecheckerOptions.t; [@opaque]
  inference_env: Typing_inference_env.t;
  tpenv: Type_parameter_env.t;
  condition_types: decl_ty SMap.t;
  pessimize: bool;
  fun_tast_info: fun_tast_info option;
}
[@@deriving show]

type program = (ty, unit, saved_env, ty) Aast.program [@@deriving show]

type def = (ty, unit, saved_env, ty) Aast.def

type expr = (ty, unit, saved_env, ty) Aast.expr

type expr_ = (ty, unit, saved_env, ty) Aast.expr_

type stmt = (ty, unit, saved_env, ty) Aast.stmt

type stmt_ = (ty, unit, saved_env, ty) Aast.stmt_

type block = (ty, unit, saved_env, ty) Aast.block

type class_ = (ty, unit, saved_env, ty) Aast.class_

type class_id = (ty, unit, saved_env, ty) Aast.class_id

type type_hint = ty Aast.type_hint

type targ = ty Aast.targ

type class_get_expr = (ty, unit, saved_env, ty) Aast.class_get_expr

type class_typeconst_def = (ty, unit, saved_env, ty) Aast.class_typeconst_def

type user_attribute = (ty, unit, saved_env, ty) Aast.user_attribute

type fun_ = (ty, unit, saved_env, ty) Aast.fun_

type file_attribute = (ty, unit, saved_env, ty) Aast.file_attribute

type fun_def = (ty, unit, saved_env, ty) Aast.fun_def

type fun_param = (ty, unit, saved_env, ty) Aast.fun_param

type fun_variadicity = (ty, unit, saved_env, ty) Aast.fun_variadicity

type func_body = (ty, unit, saved_env, ty) Aast.func_body

type method_ = (ty, unit, saved_env, ty) Aast.method_

type class_var = (ty, unit, saved_env, ty) Aast.class_var

type class_const = (ty, unit, saved_env, ty) Aast.class_const

type tparam = (ty, unit, saved_env, ty) Aast.tparam

type typedef = (ty, unit, saved_env, ty) Aast.typedef

type record_def = (ty, unit, saved_env, ty) Aast.record_def

type gconst = (ty, unit, saved_env, ty) Aast.gconst

let empty_saved_env tcopt : saved_env =
  {
    tcopt;
    inference_env = Typing_inference_env.empty_inference_env;
    tpenv = Type_parameter_env.empty;
    condition_types = SMap.empty;
    pessimize = false;
    fun_tast_info = None;
  }

(* Used when an env is needed in codegen.
 * TODO: (arkumar,wilfred,thomasjiang) T42509373 Fix when when needed
 *)
let dummy_saved_env = empty_saved_env GlobalOptions.default

let dummy_type_hint (hint : hint option) : ty * hint option =
  (Typing_defs.mk (Typing_reason.Rnone, Typing_defs.Tdynamic), hint)

(* Helper function to create an annotation for a typed and positioned expression.
 * Do not construct this tuple directly - at some point we will build
 * some abstraction in so that we can change the representation (e.g. put
 * further annotations on the expression) as we see fit.
 *)
let make_expr_annotation _p ty : ty = ty

(* Helper function to create a typed and positioned expression.
 * Do not construct this triple directly - at some point we will build
 * some abstraction in so that we can change the representation (e.g. put
 * further annotations on the expression) as we see fit.
 *)
let make_typed_expr p ty te : expr = (make_expr_annotation p ty, p, te)

(* Get the position of an expression *)
let get_position ((_, p, _) : expr) = p

(* Get the type of an expression *)
let get_type ((ty, _, _) : expr) = ty

let nast_converter =
  object
    inherit [_] Aast.map

    method on_'ex _ _ = ()

    method on_'fb _ _fb = Nast.Named

    method on_'en _ _ = ()

    method on_'hi _ _ = ()
  end

let to_nast p = nast_converter#on_program () p

let to_nast_expr (tast : expr) : Nast.expr = nast_converter#on_expr () tast

let to_nast_class_id_ cid = nast_converter#on_class_id_ () cid
