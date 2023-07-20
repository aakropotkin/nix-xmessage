/* ========================================================================== *
 *
 *
 *
 * -------------------------------------------------------------------------- */

#include <nix/command.hh>
#include <nix/eval.hh>
#include <nix/eval-cache.hh>
#include <nix/eval-inline.hh>
#include <nix/primops.hh>
#include <nix/names.hh>
#include <nix/util.hh>


/* -------------------------------------------------------------------------- */

using namespace nix;
using namespace nix::flake;


/* -------------------------------------------------------------------------- */

namespace nix {

  static RunOptions
xmessageOptions( const Strings & args )
{
  auto env = getEnv();
  return {
    .program     = "xmessage",
    .searchPath  = true,
    .args        = args,
    .environment = env
  };
}

  std::string
runXMessage( std::string_view msg )
{
  std::list<std::string> args;
  args.emplace_back( msg );
  RunOptions opts = xmessageOptions( args );
  opts.input = {};

  auto res = runProgram( std::move( opts ) );

  if ( ! statusOk( res.first ) ) { return ""; }

  return res.second;
}


/* -------------------------------------------------------------------------- */

  static void
prim_xmessage(
  EvalState & state, const PosIdx pos, Value ** args, Value & v
)
{
  const std::string message( state.forceStringNoCtx( * args[0], pos, "" ) );
  runXMessage( message );
  v = * args[1];
}

static RegisterPrimOp primop_xmessage( {
  .name = "xmessage",
  .args = { "message", "expr" },
  .doc  = R"(
    Print a string using `xmessage', and return second argument "as is".
  )",
  .fun = prim_xmessage,
} );


/* -------------------------------------------------------------------------- */

}  /* End namespace `nix' */


/* -------------------------------------------------------------------------- *
 *
 *
 *
 * ========================================================================== */
