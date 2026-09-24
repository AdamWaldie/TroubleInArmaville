class RscTitles
{
	class default {
		idd = -3;
		fadeout=0;
		fadein=0;
		duration = 99999;
		onLoad = "";
	};

	// ============================================================================
	// TTTWarmup - "Selecting Roles: N" during the pre-round warmup, in the same
	// centre-top position/casing style as TTTHud's own round-timer bar (not the
	// same titleRsc resource though: TTTHud doesn't exist yet at this point -
	// role isn't assigned, so there's no badge/credits/keybinds to show - and
	// this phase is over well before TTTHud is ever created, so the two never
	// overlap; TTTHud's own titleRsc call simply evicts this one when the round
	// goes live, same single-slot behaviour used deliberately here instead of
	// worked around). Driven by Waldo_fnc_warmupBar.
	// ============================================================================
	class TTTWarmup {
		idd = -1;
		fadeout = 0;
		fadein = 0;
		duration = 99999;
		onLoad = "with uiNamespace do {TTTWarmup = _this select 0}";

		class controlsBackground {
			class twShadow: RscText {
				idc = -1;
				x = ((safezoneX + (0.5 * safezoneW)) - (0.18 * safezoneW)) - (0.004 * safezoneH);
				y = (safezoneY + (0.015 * safezoneH)) - (0.004 * safezoneH);
				w = (0.36 * safezoneW) + (0.008 * safezoneH);
				h = (0.062 * safezoneH) + (0.008 * safezoneH);
				colorBackground[] = WALDO_SHADOW;
				style = 0;
			};
			class twBG: RscText {
				idc = -1;
				x = (safezoneX + (0.5 * safezoneW)) - (0.18 * safezoneW);
				y = safezoneY + (0.015 * safezoneH);
				w = 0.36 * safezoneW;
				h = 0.062 * safezoneH;
				colorBackground[] = WALDO_HEADERBG;
				style = 0;
			};
			class twAccent: RscText {
				idc = -1;
				x = (safezoneX + (0.5 * safezoneW)) - (0.18 * safezoneW);
				y = (safezoneY + (0.015 * safezoneH)) + (0.062 * safezoneH);
				w = 0.36 * safezoneW;
				h = 0.006 * safezoneH;
				colorBackground[] = WALDO_ACCENT;
				style = 0;
			};
			class twText: RscText {
				idc = 3630;
				text = "";
				x = (safezoneX + (0.5 * safezoneW)) - (0.18 * safezoneW);
				y = safezoneY + (0.015 * safezoneH);
				w = 0.36 * safezoneW;
				h = 0.062 * safezoneH;
				colorBackground[] = {0,0,0,0};
				colorText[] = {0.95,0.93,0.86,1};
				style = ST_CENTER;   // vertical centring in script via ctrlTextHeight
				font = "PuristaBold";
				sizeEx = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.35);
				shadow = 1;
			};
		};
	};

	class TTTHud {
		idd = -1;
		fadeout=0;
		fadein=0;
		duration = 99999;
		// Hides every script-controlled element the instant the display exists.
		// Without this they render at their config defaults until fn_initHud
		// catches up: the ping wheel is centre-screen, so it flashed across the
		// middle at round start, and all nine crests drew stacked on top of each
		// other bottom-right. onLoad is the earliest available hook - doing it in
		// fn_initHud is already too late by a frame or two.
		onLoad = "with uiNamespace do {TTTHud = _this select 0}; {((_this select 0) displayCtrl _x) ctrlShow false} forEach [3520,1290,1291,1292,1293,1294,1295,999,1000,1001,1272,1002,1003,1004,1005,1006,1300,1301,1302,1303,1304,1305,1306,1310,1311,1312,1313,1314,1315,1316,1320,1321,1322,1323,1324,1325,1326,1330,1331,1332,1333,1334,1335,1336,1340,1341,1342,1343,1344,1345,1346,1350,1351,1352,1353,1354,1355,1356,1360,1361,1362,1363,1364,1365,1366,1370,1371,1372,1373,1374,1375,1376];";

		// GMod-TTT style role crest: a circular badge with the role's letter
		// (T / D / I / J) centred in it, tinted to the role colour. The badge is
		// SQUARE (w == h, both in safezoneH units) so ui\role.paa renders as a
		// true circle and stays fully on-screen — the old height used safezoneW,
		// which stretched it into an off-screen ellipse on widescreen.
		class controlsBackground {
			// Drop shadow behind the whole crest: a dedicated soft Gaussian-blurred
			// disc, not an offset dark-tinted copy of the fill - that old technique
			// produced a hard-edged flat silhouette instead of an actual soft shadow.
			//
			// All three badge images (role/rolebg/roleshadow) are real .paa, not
			// .png. .png first seemed fine (role.png/rolebg.png loaded live while
			// roleshadow.png alone threw "Cannot load texture"), but rolebg.png
			// then failed the exact same way on a later test with no code change
			// in between - so this isn't about any one image's content, it's that
			// this engine build/version doesn't reliably support raw PNG for these
			// controls at all. Converted with a real DXT5 encoder
			// (github.com/woozymasta/paa) rather than a hand-rolled one, since a
			// subtly wrong PAA would just trade one silent load failure for
			// another.

			// The old "Rank Disc" shared backing (rankDiscRim/rankDiscAccent,
			// idc 1270/1271) is gone. It existed because styles 1-7 had no
			// material of their own - they were decorations hung off style 0's
			// badge ring, so they needed something behind that ring to make
			// them read as a crest rather than as loose marks. Every one of
			// them now owns its own shadow/border/plate (see the block further
			// down), so a shared backing has nothing left to back, and keeping
			// it would just double up a second rim behind each style's own.
			// idc 1272, not -1: style 8 (Stamped Tag) doesn't use the ring at
			// all and needs to hide this too, or its soft shadow blob would
			// linger behind style 8's own plate with nothing left to belong to.
			class roleShadow: RscPicture
			{
				idc = 1272;
				text = "ui\roleshadow.paa";
				x = ((safezoneW + safezoneX) - (0.175 * safezoneH)) + (0.008 * safezoneH);
				y = ((safezoneH + safezoneY) - (0.185 * safezoneH)) + (0.010 * safezoneH);
				w = 0.15 * safezoneH;
				h = 0.15 * safezoneH;
				color = [0,0,0,0.8];
			};
			// The white "face" showing through the ring's hole. Was briefly
			// retired while style 0 borrowed another style's look; it's back
			// and shown for style 0 only, along with the rest of the ring,
			// because style 0 is the untouched original and this disc is part
			// of that original. No other style shows it - they all replace the
			// ring outright rather than decorating it.
			class roleTextBGBG: RscPicture
			{
				idc = 999;
				text = "ui\rolebg.paa";
				x = (safezoneW + safezoneX) - (0.175 * safezoneH);
				y = (safezoneH + safezoneY) - (0.185 * safezoneH);
				w = 0.15 * safezoneH;
				h = 0.15 * safezoneH;
				// Raised from 0.5. At 0.5 this disc was half-transparent, so what
				// sat behind the role letter was whatever terrain happened to be
				// there - near-invisible against bright ground, a grey smudge
				// against dark. The medallion never read as a solid object and the
				// letter's legibility changed shot to shot. At 0.72 it's a
				// consistent pale face on any background, which is also closer to
				// the solid disc of the GMod-TTT badge this is an homage to - so it
				// reads as more like the original reference, not less.
				color = [1,1,1,0.72];
			};
			class roleTextBG: RscPicture
			{
				idc = 1000;
				text = "ui\role.paa";
				x = (safezoneW + safezoneX) - (0.175 * safezoneH);
				y = (safezoneH + safezoneY) - (0.185 * safezoneH);
				w = 0.15 * safezoneH;
				h = 0.15 * safezoneH;
			};
			class roleText: RscText
			{
				idc = 1001;
				text = "";
				x = (safezoneW + safezoneX) - (0.175 * safezoneH);
				y = (safezoneH + safezoneY) - (0.185 * safezoneH);
				w = 0.15 * safezoneH;
				h = 0.15 * safezoneH;
				// CT_STRUCTURED_TEXT's valign='middle' (the old control type here) was
				// a documented engine bug - BI forum reports confirm valign has no real
				// effect on RscStructuredText - so switching to plain RscText was the
				// right call. But ST_VCENTER (which used to be added here) is NOT a
				// "centre vertically" flag despite the name - BIKI documents it (with
				// ST_UP/ST_DOWN) as a VERTICAL/ROTATED TEXT ORIENTATION mode that
				// "should not be mixed with any other styles", which is exactly what
				// combining it with ST_CENTER did. That's almost certainly what threw
				// the letter noticeably off-position rather than just high/low by a
				// few pixels. ST_CENTER alone handles horizontal centring correctly;
				// vertical centring is done for real below, in fn_initHud.sqf, via
				// ctrlTextHeight's actual measured value - not another guessed offset.
				style = ST_CENTER;
				font = "PuristaBold";
				// ~59% of the badge box - confirmed live that 0.075 (50%) still
				// read too small, so this jumps further than the last increment
				// rather than inching up again. Still a bit short of the old 0.095
				// (63%, no margin at all against the ring) to keep some breathing
				// room.
				sizeEx = 0.088 * safezoneH;
				// Was false. This is the only text control in the whole HUD without
				// a shadow, and it's the largest one - the role letter sits over a
				// pale disc whose own brightness varies with the terrain behind it,
				// so an unshadowed glyph had nothing holding its edge. Every other
				// label here already uses shadow = 1.
				shadow = 1;
				colorBackground[] = {0,0,0,0};
			};
			// Credits readout: a proper casing pill (shadow + dark base + accent line)
			// matching the shop/debug header treatment, instead of bare floating text.
			class roleCreditsShadow: RscText
			{
				idc = 1004;
				x = ((safezoneW + safezoneX) - (0.175 * safezoneH)) - (0.004 * safezoneH);
				y = ((safezoneH + safezoneY) - (0.225 * safezoneH)) - (0.004 * safezoneH);
				w = (0.15 * safezoneH) + (0.008 * safezoneH);
				h = (0.03 * safezoneH) + (0.008 * safezoneH);
				colorBackground[] = WALDO_SHADOW;
				style = 0;
			};
			class roleCreditsBG: RscText
			{
				idc = 1005;
				x = (safezoneW + safezoneX) - (0.175 * safezoneH);
				y = (safezoneH + safezoneY) - (0.225 * safezoneH);
				w = 0.15 * safezoneH;
				h = 0.03 * safezoneH;
				colorBackground[] = WALDO_HEADERBG;
				style = 0;
			};
			// The one piece of amber on Original. Every other style carries a fixed
			// amber mark as the thread that ties the crest family together, and
			// Original had none - it was the odd one out on a shelf of nine. A
			// hairline along the pill's top edge is the smallest thing that joins
			// it to the rest: it doubles as the top bevel every other panel in this
			// HUD already has (see s8Highlight), it doesn't touch the silhouette,
			// and it leaves the role-tinted accent line at the pill's bottom - the
			// part that actually carries Original's identity - exactly as it was.
			// Part of the credits group, so it hides with the pill for roles that
			// have no credits rather than leaving a stray line under the badge.
			class roleCreditsHighlight: RscText
			{
				idc = 1006;
				x = (safezoneW + safezoneX) - (0.175 * safezoneH);
				y = (safezoneH + safezoneY) - (0.225 * safezoneH);
				w = 0.15 * safezoneH;
				h = 0.0025 * safezoneH;
				colorBackground[] = WALDO_ACCENT;   // fixed amber, never role-tinted
				style = 0;
			};
			class roleCreditsAccent: RscText
			{
				idc = 1003;
				x = (safezoneW + safezoneX) - (0.175 * safezoneH);
				y = ((safezoneH + safezoneY) - (0.225 * safezoneH)) + (0.03 * safezoneH) - (0.0025 * safezoneH);
				w = 0.15 * safezoneH;
				h = 0.0025 * safezoneH;
				colorBackground[] = WALDO_ACCENT;   // tinted to the role colour at runtime
				style = 0;
			};
			class roleCredits: RscText
			{
				idc = 1002;
				text = "";
				x = (safezoneW + safezoneX) - (0.175 * safezoneH);
				y = (safezoneH + safezoneY) - (0.225 * safezoneH);
				w = 0.15 * safezoneH;
				h = 0.03 * safezoneH;
				colorBackground[] = {0,0,0,0};
				// Was pure white, the only pure-white text anywhere in this HUD -
				// next to the cream every other label uses it read colder and
				// cheaper than its surroundings. Same cream now. Deliberately still
				// not role-tinted (see fn_initHud.sqf's note on why).
				colorText[] = {0.95, 0.93, 0.86, 1};
				style = ST_CENTER;
				font = "PuristaBold";
				sizeEx = 0.021 * safezoneH;
				shadow = 1;
			};

			// ====================================================================
			// Role crest styles 1-8. Style 0 above is the original GMod-TTT homage;
			// it keeps its own construction and has only had a light polish pass
			// (each change is commented at the control it touches).
			//
			// Styles 1-8 are DRAWN ARTWORK (ui/crests/*.paa), not arrangements of
			// rects. An earlier pass built them from flat rects with the theme living
			// entirely in their names, which is not a theme at all:
			//
			//   1 Field Medallion - Original's ring + a nameplate. Flat rects, not
			//                       artwork: its whole idea is to BE Original with a
			//                       nameplate, so it inherits Original's materials.
			//   2 Struck Coin   - milled rim, recessed field, exergue at the foot
			//   3 Enamel Pin    - cloisonne enamel in a brass cloison
			//   4 Dog Tag       - brushed steel on a bead chain, hole punched through
			//   5 Unit Patch    - satin stitch, merrowed amber edge
			//   6 Crate Stencil - spray through a stencil; the glyph is the UNPAINTED part
			//   7 Case File     - rubber clearance stamp on manila
			//   8 Chalk Mark    - chalk on asphalt
			//   9 Evidence Tag  - manila tag, brass eyelet punched top-right, string
			//
			// Three wells, per direction: GMod-TTT heritage (1-2), Armaville military
			// identity (3-5), TTT evidence (6-8). The artwork and its generator live in
			// tools/crestart/, so it can be re-derived rather than only replaced.
			//
			// On textures: two earlier attempts at texture-based tinting did fail, but
			// both used CONFIG-TIME tint properties on new files. The runtime path -
			// an RscPicture with no colour property, tinted by ctrlSetTextColor - has
			// always worked here and is what the live badge ring already does every
			// round. That distinction is what makes the drawn crests viable.
			//
			// Credits handling, per the direction that credit displays must either
			// be worked into the design or omitted without notice: every balance is
			// a transparent-background text control over ground its style already
			// covers. Hide it and the design is simply plainer - no bordered
			// sub-panel or inset pocket anywhere that could leave a hole. Styles 1
			// and 2 are the two whose layout reserves space for it, so their amber
			// divider/hairline hides with it and their name/letter box is re-fitted
			// over the full width in script.
			//
			// Every rect below was checked against the screen edge before being
			// written: with the anchor at RX/RY, nothing may extend past
			// RX + 0.175*safezoneH or RY + 0.185*safezoneH.
			// ====================================================================
#define RX ((safezoneW + safezoneX) - (0.175 * safezoneH))
#define RY ((safezoneH + safezoneY) - (0.185 * safezoneH))
// Same value, two names on purpose. ROLE_LETTER is only a placeholder - letters
// are ctrlSetTextColor'd to the role colour on each redraw (except Style 4's,
// which is a deliberate cream knockout on a role-coloured field). CREAM is the
// real, final colour of balance text, never role-tinted: every role colour is
// dark and saturated and these sit on near-black, so role-tinted credit text was
// low-contrast on every style (worst on Traitor red).
#define ROLE_LETTER {0.95, 0.93, 0.86, 1}
#define CREAM {0.95, 0.93, 0.86, 1}
			// Each crest is three RscPictures plus its letter and balance.
			//
			// ctrlSetTextColor multiplies the WHOLE texture, which is why the artwork
			// is split rather than shipped as one image per crest: only *_role carries
			// the material that becomes the role colour, so *_base (the shadow, and any
			// surface the role element sits ON - crate plank, asphalt, manila card) and
			// *_detail (amber fittings, bead chain, brass eyelet, clip) can keep their
			// own fixed colours. Declaration order is draw order, so base must come
			// first and detail last.
			//
			// Both mechanisms are already proven in this file, which is the whole reason
			// this approach works where earlier texture attempts failed: an RscPicture
			// with no colour property renders as authored (roleTextBG), and
			// ctrlSetTextColor tints one at runtime (roleTextBG again, every round, in
			// fn_initHud). The attempts that failed used CONFIG-TIME tint properties on
			// new files - a different thing entirely.
			//
			// All three layers share the crest's full footprint; the art places
			// everything within it. The footprint is 0.19 of safezoneH square, matching
			// Original's own overall height, anchored so its right and bottom edges land
			// exactly on the screen-edge budget (RX + 0.175, RY + 0.185).
			//
			// Letter boxes and sizes are NOT hand-picked: tools/crestart/fitletters.py
			// measures them from each crest's own body mask and verifies the glyph is
			// contained, and this block is generated from that output - so the geometry
			// here can't drift from the artwork it belongs to.
			//
			// The balance's dark backing is a flat rect, deliberately not baked into any
			// texture: a texture can't be hidden per role, so a baked band showed up on
			// Jester/Innocent as an empty holder with nothing in it.
			// ---- Style 0: Field Medallion. Restored as-is, per direction - this is the
			// style that was selected and liked in live testing, and it is the only one
			// that builds directly ON Original rather than away from it. It reuses the
			// exact same badge ring (idc 999/1000/1001 and its soft shadow, 1272),
			// textures and tuned position included, and changes only what sits under it:
			// where Original puts a full-width pill ABOVE the medallion carrying just a
			// number, this puts a nameplate BELOW it carrying the role's NAME and the
			// balance in one bar, split by an amber tick.
			//
			// Deliberately flat rects, not drawn artwork like styles 2-9. It is not
			// meant to match them - its whole idea is to be Original with a nameplate,
			// so it inherits Original's own materials.
			//
			// idcs are the 1290 block, not 1300: Struck Coin holds 1300-1306 now.
			class s1Shadow: RscText { idc = 1290; x = RX - (0.004 * safezoneH); y = RY + (0.148 * safezoneH); w = 0.158 * safezoneH; h = 0.034 * safezoneH; colorBackground[] = WALDO_SHADOW; style = 0; };
			class s1Plate: RscText { idc = 1291; x = RX; y = RY + (0.152 * safezoneH); w = 0.15 * safezoneH; h = 0.026 * safezoneH; colorBackground[] = WALDO_PLATE; style = 0; };
			class s1Accent: RscText { idc = 1292; x = RX; y = RY + (0.152 * safezoneH); w = 0.15 * safezoneH; h = 0.0025 * safezoneH; colorBackground[] = WALDO_ACCENT; style = 0; };   // tinted to the role colour at runtime
			class s1Name: RscText { idc = 1293; text = ""; x = RX + (0.004 * safezoneH); y = RY + (0.152 * safezoneH); w = 0.08 * safezoneH; h = 0.026 * safezoneH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95, 0.93, 0.86, 1}; style = ST_CENTER; font = "PuristaBold"; sizeEx = 0.017 * safezoneH; shadow = 1; };
			class s1Divider: RscText { idc = 1294; x = RX + (0.083 * safezoneH); y = RY + (0.156 * safezoneH); w = 0.0015 * safezoneH; h = 0.018 * safezoneH; colorBackground[] = WALDO_ACCENT; style = 0; };
			class s1Credits: RscText { idc = 1295; text = ""; x = RX + (0.086 * safezoneH); y = RY + (0.152 * safezoneH); w = 0.06 * safezoneH; h = 0.026 * safezoneH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95, 0.93, 0.86, 1}; style = ST_CENTER; font = "PuristaMedium"; sizeEx = 0.017 * safezoneH; shadow = 1; };

			// ---- Style 1: Struck Coin ----
			class s2Base: RscPicture { idc = 1300; text = "ui\crests\struckCoin_base.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // under the role element - shadow, and any surface it sits on
			class s2Role: RscPicture { idc = 1301; text = "ui\crests\struckCoin_role.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // TINTED to the role colour at runtime (ctrlSetTextColor)
			class s2Detail: RscPicture { idc = 1302; text = "ui\crests\struckCoin_detail.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // over the top - amber fittings, chain, eyelet, clip
			class s2Letter: RscText { idc = 1303; text = ""; x = RX + (0.039922 * safezoneH); y = RY + (0.038047 * safezoneH); w = 0.080156 * safezoneH; h = 0.080156 * safezoneH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95, 0.93, 0.86, 1}; style = ST_CENTER; font = "PuristaBold"; sizeEx = 0.072734 * safezoneH; shadow = 1; };
			class s2CreditsBand: RscText { idc = 1304; x = RX + (0.021367 * safezoneH); y = RY + (0.12711 * safezoneH); w = 0.11727 * safezoneH; h = 0.02375 * safezoneH; colorBackground[] = {0.07, 0.067, 0.055, 0.8}; style = 0; };
			class s2CreditsLip: RscText { idc = 1305; x = RX + (0.021367 * safezoneH); y = RY + (0.12711 * safezoneH); w = 0.11727 * safezoneH; h = 0.0014844 * safezoneH; colorBackground[] = WALDO_ACCENT; style = 0; };
			class s2Credits: RscText { idc = 1306; text = ""; x = RX + (0.021367 * safezoneH); y = RY + (0.12711 * safezoneH); w = 0.11727 * safezoneH; h = 0.02375 * safezoneH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95, 0.93, 0.86, 1}; style = ST_CENTER; font = "PuristaMedium"; sizeEx = 0.0171 * safezoneH; shadow = 1; };

			// ---- Style 2: Enamel Pin ----
			class s3Base: RscPicture { idc = 1310; text = "ui\crests\enamelPin_base.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // under the role element - shadow, and any surface it sits on
			class s3Role: RscPicture { idc = 1311; text = "ui\crests\enamelPin_role.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // TINTED to the role colour at runtime (ctrlSetTextColor)
			class s3Detail: RscPicture { idc = 1312; text = "ui\crests\enamelPin_detail.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // over the top - amber fittings, chain, eyelet, clip
			class s3Letter: RscText { idc = 1313; text = ""; x = RX + (0.038437 * safezoneH); y = RY + (0.038789 * safezoneH); w = 0.083125 * safezoneH; h = 0.083125 * safezoneH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95, 0.93, 0.86, 1}; style = ST_CENTER; font = "PuristaBold"; sizeEx = 0.074961 * safezoneH; shadow = 1; };
			class s3CreditsBand: RscText { idc = 1314; x = RX + (0.023594 * safezoneH); y = RY + (0.12934 * safezoneH); w = 0.11281 * safezoneH; h = 0.019297 * safezoneH; colorBackground[] = {0.07, 0.067, 0.055, 0.8}; style = 0; };
			class s3CreditsLip: RscText { idc = 1315; x = RX + (0.023594 * safezoneH); y = RY + (0.12934 * safezoneH); w = 0.11281 * safezoneH; h = 0.0014844 * safezoneH; colorBackground[] = WALDO_ACCENT; style = 0; };
			class s3Credits: RscText { idc = 1316; text = ""; x = RX + (0.023594 * safezoneH); y = RY + (0.12934 * safezoneH); w = 0.11281 * safezoneH; h = 0.019297 * safezoneH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95, 0.93, 0.86, 1}; style = ST_CENTER; font = "PuristaMedium"; sizeEx = 0.013894 * safezoneH; shadow = 1; };

			// ---- Style 3: Dog Tag ----
			class s4Base: RscPicture { idc = 1320; text = "ui\crests\dogTag_base.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // under the role element - shadow, and any surface it sits on
			class s4Role: RscPicture { idc = 1321; text = "ui\crests\dogTag_role.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // TINTED to the role colour at runtime (ctrlSetTextColor)
			class s4Detail: RscPicture { idc = 1322; text = "ui\crests\dogTag_detail.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // over the top - amber fittings, chain, eyelet, clip
			class s4Letter: RscText { idc = 1323; text = ""; x = RX + (0.036953 * safezoneH); y = RY + (0.061797 * safezoneH); w = 0.080156 * safezoneH; h = 0.041563 * safezoneH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95, 0.93, 0.86, 1}; style = ST_CENTER; font = "PuristaBold"; sizeEx = 0.037109 * safezoneH; shadow = 1; };
			class s4CreditsBand: RscText { idc = 1324; x = RX + (0.021367 * safezoneH); y = RY + (0.11004 * safezoneH); w = 0.11727 * safezoneH; h = 0.015586 * safezoneH; colorBackground[] = {0.07, 0.067, 0.055, 0.8}; style = 0; };
			class s4CreditsLip: RscText { idc = 1325; x = RX + (0.021367 * safezoneH); y = RY + (0.11004 * safezoneH); w = 0.11727 * safezoneH; h = 0.0014844 * safezoneH; colorBackground[] = WALDO_ACCENT; style = 0; };
			class s4Credits: RscText { idc = 1326; text = ""; x = RX + (0.021367 * safezoneH); y = RY + (0.11004 * safezoneH); w = 0.11727 * safezoneH; h = 0.015586 * safezoneH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95, 0.93, 0.86, 1}; style = ST_CENTER; font = "PuristaMedium"; sizeEx = 0.011222 * safezoneH; shadow = 1; };

			// ---- Style 4: Unit Patch ----
			class s5Base: RscPicture { idc = 1330; text = "ui\crests\unitPatch_base.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // under the role element - shadow, and any surface it sits on
			class s5Role: RscPicture { idc = 1331; text = "ui\crests\unitPatch_role.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // TINTED to the role colour at runtime (ctrlSetTextColor)
			class s5Detail: RscPicture { idc = 1332; text = "ui\crests\unitPatch_detail.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // over the top - amber fittings, chain, eyelet, clip
			class s5Letter: RscText { idc = 1333; text = ""; x = RX + (0.026562 * safezoneH); y = RY + (0.035078 * safezoneH); w = 0.10687 * safezoneH; h = 0.068281 * safezoneH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95, 0.93, 0.86, 1}; style = ST_CENTER; font = "PuristaBold"; sizeEx = 0.061602 * safezoneH; shadow = 1; };
			class s5CreditsBand: RscText { idc = 1334; x = RX + (0.034727 * safezoneH); y = RY + (0.11078 * safezoneH); w = 0.090547 * safezoneH; h = 0.016328 * safezoneH; colorBackground[] = {0.07, 0.067, 0.055, 0.8}; style = 0; };
			class s5CreditsLip: RscText { idc = 1335; x = RX + (0.034727 * safezoneH); y = RY + (0.11078 * safezoneH); w = 0.090547 * safezoneH; h = 0.0014844 * safezoneH; colorBackground[] = WALDO_ACCENT; style = 0; };
			class s5Credits: RscText { idc = 1336; text = ""; x = RX + (0.034727 * safezoneH); y = RY + (0.11078 * safezoneH); w = 0.090547 * safezoneH; h = 0.016328 * safezoneH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95, 0.93, 0.86, 1}; style = ST_CENTER; font = "PuristaMedium"; sizeEx = 0.011756 * safezoneH; shadow = 1; };

			// ---- Style 5: Crate Stencil ----
			class s6Base: RscPicture { idc = 1340; text = "ui\crests\crateStencil_base.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // under the role element - shadow, and any surface it sits on
			class s6Role: RscPicture { idc = 1341; text = "ui\crests\crateStencil_role.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // TINTED to the role colour at runtime (ctrlSetTextColor)
			class s6Detail: RscPicture { idc = 1342; text = "ui\crests\crateStencil_detail.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // over the top - amber fittings, chain, eyelet, clip
			class s6Letter: RscText { idc = 1343; text = ""; x = RX + (0.013203 * safezoneH); y = RY + (0.044727 * safezoneH); w = 0.13359 * safezoneH; h = 0.068281 * safezoneH; colorBackground[] = {0,0,0,0}; colorText[] = {0.227, 0.243, 0.165, 1}; style = ST_CENTER; font = "PuristaBold"; sizeEx = 0.061602 * safezoneH; shadow = 1; };
			class s6CreditsBand: RscText { idc = 1344; x = RX + (0.019141 * safezoneH); y = RY + (0.11969 * safezoneH); w = 0.12172 * safezoneH; h = 0.017813 * safezoneH; colorBackground[] = {0.07, 0.067, 0.055, 0.8}; style = 0; };
			class s6CreditsLip: RscText { idc = 1345; x = RX + (0.019141 * safezoneH); y = RY + (0.11969 * safezoneH); w = 0.12172 * safezoneH; h = 0.0014844 * safezoneH; colorBackground[] = WALDO_ACCENT; style = 0; };
			class s6Credits: RscText { idc = 1346; text = ""; x = RX + (0.019141 * safezoneH); y = RY + (0.11969 * safezoneH); w = 0.12172 * safezoneH; h = 0.017813 * safezoneH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95, 0.93, 0.86, 1}; style = ST_CENTER; font = "PuristaMedium"; sizeEx = 0.012825 * safezoneH; shadow = 1; };

			// ---- Style 6: Case File ----
			class s7Base: RscPicture { idc = 1350; text = "ui\crests\caseFile_base.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // under the role element - shadow, and any surface it sits on
			class s7Role: RscPicture { idc = 1351; text = "ui\crests\caseFile_role.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // TINTED to the role colour at runtime (ctrlSetTextColor)
			class s7Detail: RscPicture { idc = 1352; text = "ui\crests\caseFile_detail.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // over the top - amber fittings, chain, eyelet, clip
			class s7Letter: RscText { idc = 1353; text = ""; x = RX + (0.051797 * safezoneH); y = RY + (0.040273 * safezoneH); w = 0.062344 * safezoneH; h = 0.050469 * safezoneH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95, 0.93, 0.86, 1}; style = ST_CENTER; font = "PuristaBold"; sizeEx = 0.045273 * safezoneH; shadow = 1; };
			class s7CreditsBand: RscText { idc = 1354; x = RX + (0.0072656 * safezoneH); y = RY + (0.14344 * safezoneH); w = 0.14547 * safezoneH; h = 0.017813 * safezoneH; colorBackground[] = {0.07, 0.067, 0.055, 0.8}; style = 0; };
			class s7CreditsLip: RscText { idc = 1355; x = RX + (0.0072656 * safezoneH); y = RY + (0.14344 * safezoneH); w = 0.14547 * safezoneH; h = 0.0014844 * safezoneH; colorBackground[] = WALDO_ACCENT; style = 0; };
			class s7Credits: RscText { idc = 1356; text = ""; x = RX + (0.0072656 * safezoneH); y = RY + (0.14344 * safezoneH); w = 0.14547 * safezoneH; h = 0.017813 * safezoneH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95, 0.93, 0.86, 1}; style = ST_CENTER; font = "PuristaMedium"; sizeEx = 0.012825 * safezoneH; shadow = 1; };

			// ---- Style 7: Chalk Mark ----
			class s8Base: RscPicture { idc = 1360; text = "ui\crests\chalkMark_base.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // under the role element - shadow, and any surface it sits on
			class s8Role: RscPicture { idc = 1361; text = "ui\crests\chalkMark_role.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // TINTED to the role colour at runtime (ctrlSetTextColor)
			class s8Detail: RscPicture { idc = 1362; text = "ui\crests\chalkMark_detail.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // over the top - amber fittings, chain, eyelet, clip
			class s8Letter: RscText { idc = 1363; text = ""; x = RX + (0.031016 * safezoneH); y = RY + (0.041016 * safezoneH); w = 0.097969 * safezoneH; h = 0.083125 * safezoneH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95, 0.93, 0.86, 1}; style = ST_CENTER; font = "PuristaBold"; sizeEx = 0.074961 * safezoneH; shadow = 1; };
			class s8CreditsBand: RscText { idc = 1364; x = RX + (0.026562 * safezoneH); y = RY + (0.14641 * safezoneH); w = 0.10687 * safezoneH; h = 0.019297 * safezoneH; colorBackground[] = {0.07, 0.067, 0.055, 0.8}; style = 0; };
			class s8CreditsLip: RscText { idc = 1365; x = RX + (0.026562 * safezoneH); y = RY + (0.14641 * safezoneH); w = 0.10687 * safezoneH; h = 0.0014844 * safezoneH; colorBackground[] = WALDO_ACCENT; style = 0; };
			class s8Credits: RscText { idc = 1366; text = ""; x = RX + (0.026562 * safezoneH); y = RY + (0.14641 * safezoneH); w = 0.10687 * safezoneH; h = 0.019297 * safezoneH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95, 0.93, 0.86, 1}; style = ST_CENTER; font = "PuristaMedium"; sizeEx = 0.013894 * safezoneH; shadow = 1; };

			// ---- Style 8: Evidence Tag ----
			class s9Base: RscPicture { idc = 1370; text = "ui\crests\evidenceTag_base.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // under the role element - shadow, and any surface it sits on
			class s9Role: RscPicture { idc = 1371; text = "ui\crests\evidenceTag_role.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // TINTED to the role colour at runtime (ctrlSetTextColor)
			class s9Detail: RscPicture { idc = 1372; text = "ui\crests\evidenceTag_detail.paa"; x = RX - (0.015 * safezoneH); y = RY - (0.005 * safezoneH); w = 0.19 * safezoneH; h = 0.19 * safezoneH; };   // over the top - amber fittings, chain, eyelet, clip
			class s9Letter: RscText { idc = 1373; text = ""; x = RX + (0.060703 * safezoneH); y = RY + (0.052891 * safezoneH); w = 0.053437 * safezoneH; h = 0.0475 * safezoneH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95, 0.93, 0.86, 1}; style = ST_CENTER; font = "PuristaBold"; sizeEx = 0.043047 * safezoneH; shadow = 1; };
			class s9CreditsBand: RscText { idc = 1374; x = RX + (0.045859 * safezoneH); y = RY + (0.14344 * safezoneH); w = 0.080156 * safezoneH; h = 0.019297 * safezoneH; colorBackground[] = {0.07, 0.067, 0.055, 0.8}; style = 0; };
			class s9CreditsLip: RscText { idc = 1375; x = RX + (0.045859 * safezoneH); y = RY + (0.14344 * safezoneH); w = 0.080156 * safezoneH; h = 0.0014844 * safezoneH; colorBackground[] = WALDO_ACCENT; style = 0; };
			class s9Credits: RscText { idc = 1376; text = ""; x = RX + (0.045859 * safezoneH); y = RY + (0.14344 * safezoneH); w = 0.080156 * safezoneH; h = 0.019297 * safezoneH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95, 0.93, 0.86, 1}; style = ST_CENTER; font = "PuristaMedium"; sizeEx = 0.013894 * safezoneH; shadow = 1; };
#undef RX
#undef RY
#undef ROLE_LETTER
#undef CREAM

			// Key-hints panel (bottom-left): a normal game gives a player no other
			// way to learn what's bound, and dev-only binds are even less
			// discoverable - so this lists whatever's actually relevant to the
			// current role, plus the dev binds too when Testing Mode is on
			// (Waldo_fnc_initHud populates idc 1010, re-run on every role change).
			// Sizes here are placeholders - Waldo_fnc_initHud resizes all three
			// via ctrlSetPosition to fit however many lines actually apply (6
			// without Testing Mode, up to 8 with it), so this never sits around
			// as a fixed box mostly empty.
			// ====================================================================
			// Top bar: round timer (counts down, always visible while the round is
			// live) + a horizontal keybind row directly below it that fades out
			// completely a few seconds after each (re)draw - replaces the old
			// bottom-left key-hints panel and the server's per-second hintSilent
			// timer broadcast (Waldo_fnc_roundLoop now only owns game logic; the
			// client computes and renders its own countdown locally from the
			// already-broadcast timelimit/Waldo_startTime, see Waldo_fnc_topBarTimer).
			// Centred top, matching this mission pack's shared WALDO_CASING look.
			// 3600-3603: timer shadow/casing/accent/text. 3610-3614: keybind row
			// shadow/casing/2 text lines (up to 8 items under Testing Mode don't
			// fit one line without clipping - CT_STATIC never wraps, it just cuts
			// overflow - so the row is genuinely two stacked lines, not one).
			// ====================================================================
			class topBarTimerShadow: RscText
			{
				idc = 3600;
				x = ((safezoneX + (0.5 * safezoneW)) - (0.18 * safezoneW)) - (0.004 * safezoneH);
				y = (safezoneY + (0.015 * safezoneH)) - (0.004 * safezoneH);
				w = (0.36 * safezoneW) + (0.008 * safezoneH);
				h = (0.062 * safezoneH) + (0.008 * safezoneH);
				colorBackground[] = WALDO_SHADOW;
				style = 0;
			};
			class topBarTimerBG: RscText
			{
				idc = 3601;
				x = (safezoneX + (0.5 * safezoneW)) - (0.18 * safezoneW);
				y = safezoneY + (0.015 * safezoneH);
				w = 0.36 * safezoneW;
				h = 0.062 * safezoneH;
				colorBackground[] = WALDO_HEADERBG;
				style = 0;
			};
			// Baseline/full-width position for the accent bar - Waldo_fnc_topBarTimer
			// shrinks its w/x at runtime to double as a countdown progress bar (see
			// there for why: needs a live fraction-of-time-remaining this file can't
			// know), and flashes it in the last 30s. These values are just its
			// starting (100% remaining) state.
			class topBarTimerAccent: RscText
			{
				idc = 3602;
				x = (safezoneX + (0.5 * safezoneW)) - (0.18 * safezoneW);
				y = (safezoneY + (0.015 * safezoneH)) + (0.062 * safezoneH);
				w = 0.36 * safezoneW;
				h = 0.006 * safezoneH;
				colorBackground[] = WALDO_ACCENT;
				style = 0;
			};
			class topBarTimerText: RscText
			{
				idc = 3603;
				text = "";
				x = (safezoneX + (0.5 * safezoneW)) - (0.18 * safezoneW);
				y = safezoneY + (0.015 * safezoneH);
				w = 0.36 * safezoneW;
				h = 0.062 * safezoneH;
				colorBackground[] = {0,0,0,0};
				colorText[] = {0.95,0.93,0.86,1};
				// ST_CENTER alone, NOT "+ ST_VCENTER" - that combination is invalid
				// (see roleText's own fix above); vertical centring is done in
				// script via ctrlTextHeight, same as roleText.
				style = ST_CENTER;
				font = "PuristaBold";
				sizeEx = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.35);
				shadow = 1;
			};
			class topBarHintShadow: RscText
			{
				idc = 3610;
				x = ((safezoneX + (0.5 * safezoneW)) - (0.18 * safezoneW)) - (0.004 * safezoneH);
				y = ((safezoneY + (0.015 * safezoneH)) + (0.068 * safezoneH)) - (0.004 * safezoneH);
				w = (0.36 * safezoneW) + (0.008 * safezoneH);
				h = (0.075 * safezoneH) + (0.008 * safezoneH);
				colorBackground[] = {0, 0, 0, 0.55};
				style = 0;
			};
			class topBarHintBG: RscText
			{
				idc = 3611;
				x = (safezoneX + (0.5 * safezoneW)) - (0.18 * safezoneW);
				y = (safezoneY + (0.015 * safezoneH)) + (0.068 * safezoneH);
				w = 0.36 * safezoneW;
				h = 0.075 * safezoneH;
				colorBackground[] = {0.105, 0.11, 0.095, 0.85};
				style = 0;
			};
			// Two stacked lines, not one - a plain RscText/CT_STATIC control never
			// wraps (it just cuts overflow), and 7 keybinds under Testing Mode
			// never fit one line at a readable size regardless of box width.
			// Waldo_fnc_initHud splits the current role's hint list evenly across
			// both.
			class topBarHintText: RscText
			{
				idc = 3612;
				text = "";
				x = ((safezoneX + (0.5 * safezoneW)) - (0.18 * safezoneW)) + (0.015 * safezoneW);
				y = (safezoneY + (0.015 * safezoneH)) + (0.068 * safezoneH);
				w = (0.36 * safezoneW) - (0.030 * safezoneW);
				h = 0.0375 * safezoneH;
				colorBackground[] = {0,0,0,0};
				colorText[] = {0.95,0.93,0.86,1};
				style = ST_CENTER;
				font = "PuristaMedium";
				sizeEx = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.72);
				shadow = 1;
			};
			class topBarHintText2: RscText
			{
				idc = 3613;
				text = "";
				x = ((safezoneX + (0.5 * safezoneW)) - (0.18 * safezoneW)) + (0.015 * safezoneW);
				y = (safezoneY + (0.015 * safezoneH)) + (0.068 * safezoneH) + (0.0375 * safezoneH);
				w = (0.36 * safezoneW) - (0.030 * safezoneW);
				h = 0.0375 * safezoneH;
				colorBackground[] = {0,0,0,0};
				colorText[] = {0.95,0.93,0.86,1};
				style = ST_CENTER;
				font = "PuristaMedium";
				sizeEx = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.72);
				shadow = 1;
			};

			// Announcement banner (airdrops, etc. - Waldo_fnc_topBarAnnounce):
			// "pops out" from directly under the keybind row, fades in, holds,
			// fades back out - alpha 0 by default. All three (shadow/bg/text)
			// need real idc's since the fade animates all of them together.
			class topBarAnnounceShadow: RscText
			{
				idc = 3619;
				x = ((safezoneX + (0.5 * safezoneW)) - (0.18 * safezoneW)) - (0.004 * safezoneH);
				y = ((safezoneY + (0.015 * safezoneH)) + (0.149 * safezoneH)) - (0.004 * safezoneH);
				w = (0.36 * safezoneW) + (0.008 * safezoneH);
				h = (0.05 * safezoneH) + (0.008 * safezoneH);
				colorBackground[] = {0, 0, 0, 0};
				style = 0;
			};
			class topBarAnnounceBG: RscText
			{
				idc = 3620;
				x = (safezoneX + (0.5 * safezoneW)) - (0.18 * safezoneW);
				y = (safezoneY + (0.015 * safezoneH)) + (0.149 * safezoneH);
				w = 0.36 * safezoneW;
				h = 0.05 * safezoneH;
				colorBackground[] = {0.105, 0.11, 0.095, 0};
				style = 0;
			};
			class topBarAnnounceText: RscText
			{
				idc = 3621;
				text = "";
				x = (safezoneX + (0.5 * safezoneW)) - (0.18 * safezoneW);
				y = (safezoneY + (0.015 * safezoneH)) + (0.149 * safezoneH);
				w = 0.36 * safezoneW;
				h = 0.05 * safezoneH;
				colorBackground[] = {0,0,0,0};
				colorText[] = {1, 0.82, 0.25, 0};
				style = ST_CENTER;
				font = "PuristaBold";
				sizeEx = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.0);
				shadow = 1;
			};
		};

		// ========================================================================
		// Ping picker (Waldo_fnc_pingWheelOpen/Render/Close). Hold T to show it,
		// scroll to move the highlight, release T to fire it. Lives inside THIS
		// same title resource (not a second titleRsc-shown class) and is just
		// shown/hidden via ctrlShow - titleRsc only has one active slot, so a
		// second titleRsc call for a separate class would silently evict this
		// entire HUD (badge + key hints) the moment the picker first opened.
		// ========================================================================
		class Controls {
			// Row height was 0.044*safezoneH for ALL rows, but the SELECTED row
			// renders TWO lines (label at size 1.0, description at 0.8) - two
			// stacked lines at those sizes need roughly 0.09*safezoneH with a
			// real line-height margin (same "budget must exceed the actual
			// rendered size" rule as the old key-hints panel), so the
			// description clipped past the row's bottom edge every time. Rows
			// bumped to 0.075*safezoneH each (group height grown to match) fixes
			// that with real margin. `style = 0` on the group itself (overriding
			// RscControlsGroup's own default) kills the scrollbar this never
			// needed - 5 fixed rows in a group sized to fit all of them isn't
			// scrollable content to begin with.
			class pingWheelGroup: RscControlsGroup {
				idc = 3520;
				x = (safezoneX + (0.5 * safezoneW)) - (0.1 * safezoneW);
				y = safezoneY + (0.28 * safezoneH);
				w = 0.2 * safezoneW;
				h = 0.42 * safezoneH;
				style = 0;

				class Controls {
					class pwShadow: RscText {
						idc = -1;
						x = -0.004 * safezoneH;
						y = -0.004 * safezoneH;
						w = (0.2 * safezoneW) + (0.008 * safezoneH);
						h = (0.42 * safezoneH) + (0.008 * safezoneH);
						colorBackground[] = WALDO_SHADOW;
						style = 0;
					};
					class pwCasing: RscText {
						idc = -1;
						x = 0; y = 0;
						w = 0.2 * safezoneW;
						h = 0.42 * safezoneH;
						colorBackground[] = WALDO_CASING;
						style = 0;
					};
					class pwHeaderBG: RscText {
						idc = -1;
						x = 0; y = 0;
						w = 0.2 * safezoneW;
						h = 0.036 * safezoneH;
						colorBackground[] = WALDO_HEADERBG;
						style = 0;
					};
					class pwTitle: RscText {
						idc = -1;
						text = "$STR_TIA_Ui_PingHeader";
						x = 0; y = 0;
						w = 0.2 * safezoneW;
						h = 0.036 * safezoneH;
						colorBackground[] = {0,0,0,0};
						colorText[] = {0.95,0.93,0.86,1};
						style = ST_CENTER + ST_VCENTER;
						font = "PuristaBold";
						sizeEx = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.85);
						shadow = 1;
					};
					class pwAccent: RscText {
						idc = 3502;
						x = 0;
						y = 0.036 * safezoneH;
						w = 0.2 * safezoneW;
						h = 0.0025 * safezoneH;
						colorBackground[] = WALDO_ACCENT;   // tinted to the role colour at runtime
						style = 0;
					};
					class pwOpt0: RscStructuredText {
						idc = 3510;
						text = "";
						x = 0.010 * safezoneW;
						y = 0.040 * safezoneH;
						w = 0.18 * safezoneW;
						h = 0.075 * safezoneH;
						size = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.0);
						colorBackground[] = {0,0,0,0};
						class Attributes { font = "PuristaMedium"; color = "#BFBCAF"; align = "left"; shadow = 1; };
					};
					class pwOpt1: RscStructuredText {
						idc = 3511;
						text = "";
						x = 0.010 * safezoneW;
						y = 0.115 * safezoneH;
						w = 0.18 * safezoneW;
						h = 0.075 * safezoneH;
						size = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.0);
						colorBackground[] = {0,0,0,0};
						class Attributes { font = "PuristaMedium"; color = "#BFBCAF"; align = "left"; shadow = 1; };
					};
					class pwOpt2: RscStructuredText {
						idc = 3512;
						text = "";
						x = 0.010 * safezoneW;
						y = 0.190 * safezoneH;
						w = 0.18 * safezoneW;
						h = 0.075 * safezoneH;
						size = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.0);
						colorBackground[] = {0,0,0,0};
						class Attributes { font = "PuristaMedium"; color = "#BFBCAF"; align = "left"; shadow = 1; };
					};
					class pwOpt3: RscStructuredText {
						idc = 3513;
						text = "";
						x = 0.010 * safezoneW;
						y = 0.265 * safezoneH;
						w = 0.18 * safezoneW;
						h = 0.075 * safezoneH;
						size = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.0);
						colorBackground[] = {0,0,0,0};
						class Attributes { font = "PuristaMedium"; color = "#BFBCAF"; align = "left"; shadow = 1; };
					};
					class pwOpt4: RscStructuredText {
						idc = 3514;
						text = "";
						x = 0.010 * safezoneW;
						y = 0.340 * safezoneH;
						w = 0.18 * safezoneW;
						h = 0.075 * safezoneH;
						size = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.0);
						colorBackground[] = {0,0,0,0};
						class Attributes { font = "PuristaMedium"; color = "#BFBCAF"; align = "left"; shadow = 1; };
					};
				};
			};
		};
	};

	class blind {
		idd = 0;
		fadeout=0;
		fadein=0;
		duration = 99999;
		onLoad = "with uiNamespace do {blind = _this select 0}";

		class controlsBackground {
			class blindy
			{
				type = 0;
				idc = 700;
				text = "";
				style = 18;
				x = safezoneX;
				y = safezoneY;
				w = 1 * safezoneW;
				h = 1 * safezoneH;
				colorBackground[] = {0,0,0,0.9};
				colorText[] = {0.01,0.45,1,1};
				lineSpacing = 0;
				font = "PuristaMedium";
				sizeEx = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.25);
				default = false;
			};
		};
	};
};

// ============================================================================
// WaldoShop - shared buy menu dialog. A centred panel with a near-black header,
// a thin accent stripe (tinted to the role colour at runtime), a scrollable grid
// of item cards, and a description footer that updates as you hover. Cards are
// generated at runtime from the role's catalog by Waldo_fnc_openBuyMenu, so this
// shell never changes when items are added.
//   1100 title, 1101 credits, 1102 item grid, 1103 hover description,
//   1104 header bar, 1107 purchased-panel group (rows built at runtime by
//   Waldo_shopRenderPurchased, including the Y/U/J key-assign buttons),
//   1108 accent stripe (role-tinted), idc 2 close.
// ============================================================================
class WaldoShop {
	idd = -1;
	fadeout = 0.2;
	fadein = 0.2;
	movingEnable = false;
	enableSimulation = true;
	duration = 99999;
	// Same modal guard as WaldoStylePicker: notification cards are created on
	// display 46 and were drawing over this mission's dialogs instead of under
	// them. Flag while open so Waldo_fnc_ShowUiNotification queues, and drain on
	// close so nothing is lost.
	onLoad = "with uiNamespace do { WaldoShop = _this select 0 }; uiNamespace setVariable ['Waldo_uiModalOpen', true];";
	onUnload = "uiNamespace setVariable ['Waldo_uiModalOpen', false]; [] spawn Waldo_fnc_DrainUiNotificationQueue;";

	class controlsBackground {
		// Dims the world behind the panel and drops a soft shadow under it.
		class shopDim: RscText {
			idc = -1;
			x = safezoneX; y = safezoneY; w = safezoneW; h = safezoneH;
			colorBackground[] = WALDO_DIM;
			style = 0;
		};
		class shopShadow: RscText {
			idc = -1;
			x = safezoneX + (0.28 * safezoneW) - (0.006 * safezoneW);
			y = safezoneY + (0.18 * safezoneH) - (0.006 * safezoneH);
			w = (0.44 * safezoneW) + (0.012 * safezoneW);
			h = (0.64 * safezoneH) + (0.012 * safezoneH);
			colorBackground[] = WALDO_SHADOW;
			style = 0;
		};
		class shopBG: RscText {
			idc = -1;
			x = safezoneX + (0.28 * safezoneW);
			y = safezoneY + (0.18 * safezoneH);
			w = 0.44 * safezoneW;
			h = 0.64 * safezoneH;
			colorBackground[] = WALDO_CASING;
			style = 0;
		};
		class shopHeader: RscText {
			idc = 1104;
			x = safezoneX + (0.28 * safezoneW);
			y = safezoneY + (0.18 * safezoneH);
			w = 0.44 * safezoneW;
			h = 0.062 * safezoneH;
			colorBackground[] = WALDO_HEADERBG;
			style = 0;
		};
		class shopAccentBar: RscText {
			idc = 1108;
			x = safezoneX + (0.28 * safezoneW);
			y = safezoneY + (0.18 * safezoneH) + (0.062 * safezoneH);
			w = 0.44 * safezoneW;
			h = 0.006 * safezoneH;
			colorBackground[] = WALDO_ACCENT;   // tinted to the role colour at runtime
			style = 0;
		};
		class shopCredits: RscText {
			idc = 1101;
			text = "$STR_TIA_Ui_ZeroCredits";
			// Keep the right-aligned balance outside the title's full-width lane.
			// German and Russian role/armory labels need almost all of that lane
			// and otherwise paint underneath this control.
			x = safezoneX + (0.56 * safezoneW);
			y = safezoneY + (0.18 * safezoneH);
			w = 0.145 * safezoneW;
			h = 0.062 * safezoneH;
			colorBackground[] = {0,0,0,0};
			colorText[] = {0.95,0.93,0.86,1};
			style = ST_RIGHT + ST_VCENTER;
			font = "PuristaBold";
			sizeEx = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.25);
			shadow = 1;
		};
		class shopDescBG: RscText {
			idc = -1;
			x = safezoneX + (0.29 * safezoneW);
			y = safezoneY + (0.665 * safezoneH);
			w = 0.42 * safezoneW;
			h = 0.10 * safezoneH;
			colorBackground[] = WALDO_HEADERBG;
			style = 0;
		};
		class shopDesc: RscStructuredText {
			idc = 1103;
			text = "";
			x = safezoneX + (0.30 * safezoneW);
			y = safezoneY + (0.672 * safezoneH);
			w = 0.40 * safezoneW;
			h = 0.088 * safezoneH;
			size = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1);
			class Attributes {
				font = "PuristaMedium";
				color = "#F2EFE3";
				align = "left";
				shadow = 1;
			};
		};

		// "Purchased" side panel: what you already bought this round + how to use
		// it (the catalog tooltip). A second panel to the right of the main shop.
		class shopPurchBG: RscText {
			idc = -1;
			x = safezoneX + (0.73 * safezoneW);
			y = safezoneY + (0.18 * safezoneH);
			w = 0.20 * safezoneW;
			h = 0.64 * safezoneH;
			colorBackground[] = WALDO_CASING;
			style = 0;
		};
		class shopPurchHeader: RscText {
			idc = -1;
			x = safezoneX + (0.73 * safezoneW);
			y = safezoneY + (0.18 * safezoneH);
			w = 0.20 * safezoneW;
			h = 0.062 * safezoneH;
			colorBackground[] = WALDO_HEADERBG;
			style = 0;
		};
		class shopPurchAccentBar: RscText {
			idc = -1;
			x = safezoneX + (0.73 * safezoneW);
			y = safezoneY + (0.18 * safezoneH) + (0.062 * safezoneH);
			w = 0.20 * safezoneW;
			h = 0.006 * safezoneH;
			colorBackground[] = WALDO_ACCENT;
			style = 0;
		};
	};

	class Controls {
		// Header labels belong in the foreground controls layer. When declared
		// in controlsBackground they were present and addressable by IDC but did
		// not paint in-game, leaving only Credits and the empty purchased panel.
		class shopTitle: RscText {
			idc = 1100;
			text = "$STR_TIA_Ui_Shop";
			x = safezoneX + (0.295 * safezoneW);
			y = safezoneY + (0.18 * safezoneH);
			w = 0.26 * safezoneW;
			h = 0.062 * safezoneH;
			colorBackground[] = {0,0,0,0};
			colorText[] = {0.95,0.93,0.86,1};
			style = ST_LEFT;
			font = "PuristaBold";
			sizeEx = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.5);
			shadow = 1;
		};
		class shopPurchTitle: RscText {
			idc = 1105;
			text = "$STR_TIA_Ui_Purchased";
			x = safezoneX + (0.735 * safezoneW);
			y = safezoneY + (0.18 * safezoneH);
			w = 0.19 * safezoneW;
			h = 0.062 * safezoneH;
			colorText[] = {0.95,0.93,0.86,1};
			style = ST_LEFT;
			font = "PuristaBold";
			sizeEx = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.1);
			shadow = 1;
		};
		class shopGroup: RscControlsGroup {
			idc = 1102;
			x = safezoneX + (0.29 * safezoneW);
			y = safezoneY + (0.26 * safezoneH);
			w = 0.42 * safezoneW;
			h = 0.395 * safezoneH;
		};
		class shopPurchGroup: RscControlsGroup {
			idc = 1107;
			x = safezoneX + (0.735 * safezoneW);
			y = safezoneY + (0.26 * safezoneH);
			w = 0.185 * safezoneW;
			h = 0.545 * safezoneH;

			class Controls {
				// Invisible spacer, declared (not runtime-created) so the group's
				// scrollable extent is fixed at dialog-load time - a group's scroll
				// range is computed from its DECLARED children only, not whatever
				// Waldo_shopRenderPurchased ctrlCreate's into it afterwards (same
				// reason the item grid above sizes itself to fit rather than relying
				// on runtime children to trigger scrolling). This stays tall enough
				// that the group scrolls once a round's purchases run past one screen,
				// and every runtime row shares its scroll offset as a sibling in the
				// same group.
				//
				// A declared child sitting at the SAME x/y as the runtime rows/buttons
				// ate every click meant for them - a config-time control apparently
				// wins hit-testing over a ctrlCreate'd one layered "on top" of it in
				// the same group. Pushed off to a razor-thin sliver past the row
				// content's right edge (rows/buttons only ever use x in [0, 0.18*W])
				// so it still forces the same scroll-triggering height without ever
				// overlapping anything clickable.
				class shopPurchSpacer: RscStructuredText {
					idc = -1;
					text = "";
					x = 0.181 * safezoneW;
					y = 0;
					w = 0.001 * safezoneW;
					h = 2.0 * safezoneH;
				};
			};
		};
		class shopClose: RscButton {
			idc = 2;
			text = "$STR_TIA_Ui_CloseEsc";
			x = safezoneX + (0.60 * safezoneW);
			y = safezoneY + (0.775 * safezoneH);
			w = 0.10 * safezoneW;
			h = 0.04 * safezoneH;
			colorBackground[] = WALDO_BTN;
			colorBackgroundActive[] = WALDO_BTNACTIVE;
			colorText[] = {0.95,0.93,0.86,1};
			sizeEx = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1);
			action = "closeDialog 1";
		};
	};
};

// ============================================================================
// WaldoStylePicker - opened with H (Waldo_fnc_openStylePicker). Replaces the
// old cycle-through-styles-on-keypress behaviour with an actual picker: a 3x3
// grid of named cards (one per Style 0-8), the selected one highlighted by
// filling its own background with the player's role colour, so the player
// knows what they currently have without tabbing blind. Deliberately a
// single RscText per card (background colour + text together), not layered
// border+plate+label controls - an earlier layered version consistently
// rendered as blank boxes with no visible text in practice, and this is the
// simplest structure that removes any z-order dependency between sibling
// controls as a possible cause. Same shadow/casing/header/accent-stripe
// recipe as WaldoShop/WaldoScore. Card layout is declared, not generated,
// because hpp has no loops - the shared base coordinates are local
// #defines, undef'd right after this class so they don't leak into
// anything declared later in the file.
// ============================================================================
#define SP_BASEX (safezoneX + (0.325 * safezoneW))
#define SP_BASEY (safezoneY + (0.24 * safezoneH))
#define SP_CARDW (0.11 * safezoneW)
#define SP_CARDH (0.115 * safezoneH)
#define SP_COLSTEP (0.125 * safezoneW)
#define SP_ROWSTEP (0.128 * safezoneH)
class WaldoStylePicker {
	idd = -1;
	fadeout = 0.15;
	fadein = 0.15;
	movingEnable = false;
	enableSimulation = true;
	duration = 99999;
	// Notification cards are created on display 46 and were drawing OVER this
	// dialog, covering its title. Rather than fight the engine's layering, flag
	// while this is open so Waldo_fnc_ShowUiNotification queues instead of drawing,
	// then drain the queue on close so nothing is lost.
	onLoad = "with uiNamespace do { WaldoStylePicker = _this select 0 }; uiNamespace setVariable ['Waldo_uiModalOpen', true];";
	onUnload = "uiNamespace setVariable ['Waldo_uiModalOpen', false]; [] spawn Waldo_fnc_DrainUiNotificationQueue;";

	class controlsBackground {
		class spDim: RscText {
			idc = -1;
			x = safezoneX; y = safezoneY; w = safezoneW; h = safezoneH;
			colorBackground[] = WALDO_DIM;
			style = 0;
		};
		class spShadow: RscText {
			idc = -1;
			x = (safezoneX + (0.30 * safezoneW)) - (0.006 * safezoneW);
			y = (safezoneY + (0.16 * safezoneH)) - (0.006 * safezoneH);
			w = (0.40 * safezoneW) + (0.012 * safezoneW);
			h = (0.70 * safezoneH) + (0.012 * safezoneH);
			colorBackground[] = WALDO_SHADOW;
			style = 0;
		};
		class spBG: RscText {
			idc = -1;
			x = safezoneX + (0.30 * safezoneW);
			y = safezoneY + (0.16 * safezoneH);
			w = 0.40 * safezoneW;
			h = 0.70 * safezoneH;
			colorBackground[] = WALDO_CASING;
			style = 0;
		};
		class spHeader: RscText {
			idc = -1;
			x = safezoneX + (0.30 * safezoneW);
			y = safezoneY + (0.16 * safezoneH);
			w = 0.40 * safezoneW;
			h = 0.05 * safezoneH;
			colorBackground[] = WALDO_HEADERBG;
			style = 0;
		};
		class spAccentBar: RscText {
			idc = 1591;
			x = safezoneX + (0.30 * safezoneW);
			y = (safezoneY + (0.16 * safezoneH)) + (0.05 * safezoneH);
			w = 0.40 * safezoneW;
			h = 0.004 * safezoneH;
			colorBackground[] = WALDO_ACCENT;   // tinted to the role colour at runtime
			style = 0;
		};
		// ST_LEFT alone, NOT "+ ST_VCENTER" - the exact combo already
		// confirmed to render fully blank elsewhere in this file (see the
		// long comment above roleText/s3RoleName). Real vertical centring
		// is done in script instead (Waldo_fnc_openStylePicker), same
		// ctrlTextHeight technique. Full header width now that the
		// accessibility toggle moved to the bottom-left corner instead of
		// sharing this row.
		class spTitle: RscText {
			idc = 1590;
			text = "$STR_TIA_Ui_SelectStyle";
			x = safezoneX + (0.32 * safezoneW);
			y = safezoneY + (0.16 * safezoneH);
			w = 0.36 * safezoneW;
			h = 0.05 * safezoneH;
			colorBackground[] = {0,0,0,0};
			colorText[] = {0.95,0.93,0.86,1};
			style = ST_LEFT;
			font = "PuristaBold";
			sizeEx = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.4);
			shadow = 1;
		};

		// Card previews, rebuilt. They were removed entirely at one point
		// because they relied on RscPicture textures that never rendered
		// reliably at card size - the cards have been label-only ever since,
		// which made nine differently-named styles look identical until you
		// picked one. Everything is a flat RscText rect now, the one technique
		// that has never failed in this file.
		//
		// Each preview is a schematic, not a literal scale-down: the real amber
		// marks are 0.002-0.004 of safezoneH and would land on a fraction of a
		// pixel at this size. Each card keeps its style's silhouette (landscape
		// bar, narrow column, square, offset pair) and its one signature mark,
		// which is what actually tells the styles apart.
		//
		// Only the role-coloured rect in each preview carries an idc - the amber
		// and plate rects never change, so they cost nothing to leave static.
		//
		// The card itself is now a plain background with no text of its own, and
		// the label is a separate control in a band at the card's foot. It used
		// to be one control doing both jobs, which meant the script's vertical
		// centring pass shrank the card's background down to the height of its
		// own text - so the "card" was really a thin strip and the selected
		// style's highlight was a thin band rather than a filled card. Selection
		// is an amber frame behind the card instead of a role-coloured fill,
		// because the previews now carry the role colour themselves and a
		// role-filled card would swallow them.
		// Named cards. Nine designs now - Original retired, Field Medallion replaces it.
		//
		// The LABELS are not here: they live at the end of class Controls, after the
		// click targets. The invisible RscButton over each card was painting a
		// card-sized black rectangle over its own label - stock RscButton carries a
		// default colorShadow and border that draw regardless of a transparent
		// colorBackground, which is why every card read as a black box with unreadable
		// text. Those are nulled below too, but declaring the labels last means text is
		// on top whatever a button decides to paint.
		class sp0Select: RscText { idc = 1630; x = (SP_BASEX) - (0.003 * safezoneH); y = (SP_BASEY) - (0.003 * safezoneH); w = SP_CARDW + (0.006 * safezoneH); h = SP_CARDH + (0.006 * safezoneH); colorBackground[] = WALDO_ACCENT; style = 0; };
		class sp0Card: RscText { idc = 1600; text = ""; x = SP_BASEX; y = SP_BASEY; w = SP_CARDW; h = SP_CARDH; colorBackground[] = WALDO_HEADERBG; style = 0; };
		class sp1Select: RscText { idc = 1631; x = (SP_BASEX + SP_COLSTEP) - (0.003 * safezoneH); y = (SP_BASEY) - (0.003 * safezoneH); w = SP_CARDW + (0.006 * safezoneH); h = SP_CARDH + (0.006 * safezoneH); colorBackground[] = WALDO_ACCENT; style = 0; };
		class sp1Card: RscText { idc = 1601; text = ""; x = SP_BASEX + SP_COLSTEP; y = SP_BASEY; w = SP_CARDW; h = SP_CARDH; colorBackground[] = WALDO_HEADERBG; style = 0; };
		class sp2Select: RscText { idc = 1632; x = (SP_BASEX + (2 * SP_COLSTEP)) - (0.003 * safezoneH); y = (SP_BASEY) - (0.003 * safezoneH); w = SP_CARDW + (0.006 * safezoneH); h = SP_CARDH + (0.006 * safezoneH); colorBackground[] = WALDO_ACCENT; style = 0; };
		class sp2Card: RscText { idc = 1602; text = ""; x = SP_BASEX + (2 * SP_COLSTEP); y = SP_BASEY; w = SP_CARDW; h = SP_CARDH; colorBackground[] = WALDO_HEADERBG; style = 0; };
		class sp3Select: RscText { idc = 1633; x = (SP_BASEX) - (0.003 * safezoneH); y = (SP_BASEY + SP_ROWSTEP) - (0.003 * safezoneH); w = SP_CARDW + (0.006 * safezoneH); h = SP_CARDH + (0.006 * safezoneH); colorBackground[] = WALDO_ACCENT; style = 0; };
		class sp3Card: RscText { idc = 1603; text = ""; x = SP_BASEX; y = SP_BASEY + SP_ROWSTEP; w = SP_CARDW; h = SP_CARDH; colorBackground[] = WALDO_HEADERBG; style = 0; };
		class sp4Select: RscText { idc = 1634; x = (SP_BASEX + SP_COLSTEP) - (0.003 * safezoneH); y = (SP_BASEY + SP_ROWSTEP) - (0.003 * safezoneH); w = SP_CARDW + (0.006 * safezoneH); h = SP_CARDH + (0.006 * safezoneH); colorBackground[] = WALDO_ACCENT; style = 0; };
		class sp4Card: RscText { idc = 1604; text = ""; x = SP_BASEX + SP_COLSTEP; y = SP_BASEY + SP_ROWSTEP; w = SP_CARDW; h = SP_CARDH; colorBackground[] = WALDO_HEADERBG; style = 0; };
		class sp5Select: RscText { idc = 1635; x = (SP_BASEX + (2 * SP_COLSTEP)) - (0.003 * safezoneH); y = (SP_BASEY + SP_ROWSTEP) - (0.003 * safezoneH); w = SP_CARDW + (0.006 * safezoneH); h = SP_CARDH + (0.006 * safezoneH); colorBackground[] = WALDO_ACCENT; style = 0; };
		class sp5Card: RscText { idc = 1605; text = ""; x = SP_BASEX + (2 * SP_COLSTEP); y = SP_BASEY + SP_ROWSTEP; w = SP_CARDW; h = SP_CARDH; colorBackground[] = WALDO_HEADERBG; style = 0; };
		class sp6Select: RscText { idc = 1636; x = (SP_BASEX) - (0.003 * safezoneH); y = (SP_BASEY + (2 * SP_ROWSTEP)) - (0.003 * safezoneH); w = SP_CARDW + (0.006 * safezoneH); h = SP_CARDH + (0.006 * safezoneH); colorBackground[] = WALDO_ACCENT; style = 0; };
		class sp6Card: RscText { idc = 1606; text = ""; x = SP_BASEX; y = SP_BASEY + (2 * SP_ROWSTEP); w = SP_CARDW; h = SP_CARDH; colorBackground[] = WALDO_HEADERBG; style = 0; };
		class sp7Select: RscText { idc = 1637; x = (SP_BASEX + SP_COLSTEP) - (0.003 * safezoneH); y = (SP_BASEY + (2 * SP_ROWSTEP)) - (0.003 * safezoneH); w = SP_CARDW + (0.006 * safezoneH); h = SP_CARDH + (0.006 * safezoneH); colorBackground[] = WALDO_ACCENT; style = 0; };
		class sp7Card: RscText { idc = 1607; text = ""; x = SP_BASEX + SP_COLSTEP; y = SP_BASEY + (2 * SP_ROWSTEP); w = SP_CARDW; h = SP_CARDH; colorBackground[] = WALDO_HEADERBG; style = 0; };
		class sp8Select: RscText { idc = 1638; x = (SP_BASEX + (2 * SP_COLSTEP)) - (0.003 * safezoneH); y = (SP_BASEY + (2 * SP_ROWSTEP)) - (0.003 * safezoneH); w = SP_CARDW + (0.006 * safezoneH); h = SP_CARDH + (0.006 * safezoneH); colorBackground[] = WALDO_ACCENT; style = 0; };
		class sp8Card: RscText { idc = 1608; text = ""; x = SP_BASEX + (2 * SP_COLSTEP); y = SP_BASEY + (2 * SP_ROWSTEP); w = SP_CARDW; h = SP_CARDH; colorBackground[] = WALDO_HEADERBG; style = 0; };
	};

	class Controls {
		// Click targets, declared LAST (after the whole controlsBackground
		// group) so they sit on top and actually receive the click - a
		// config-declared control earlier in z-order has been seen to eat
		// clicks meant for whatever's layered under it elsewhere in this
		// HUD (see the shopPurchSpacer comment above), so the interactive
		// layer has to be the one on top here, not the decoration.
		class sp0Btn: RscButton { idc = 1640; text = ""; x = SP_BASEX; y = SP_BASEY; w = SP_CARDW; h = SP_CARDH; colorBackground[] = {0,0,0,0}; colorBackgroundActive[] = {1,1,1,0.08}; colorBackgroundDisabled[] = {0,0,0,0}; colorFocused[] = {0,0,0,0}; colorShadow[] = {0,0,0,0}; colorBorder[] = {0,0,0,0}; borderSize = 0; offsetX = 0; offsetY = 0; offsetPressedX = 0; offsetPressedY = 0; colorText[] = {0,0,0,0}; };
		class sp1Btn: RscButton { idc = 1641; text = ""; x = SP_BASEX + SP_COLSTEP; y = SP_BASEY; w = SP_CARDW; h = SP_CARDH; colorBackground[] = {0,0,0,0}; colorBackgroundActive[] = {1,1,1,0.08}; colorBackgroundDisabled[] = {0,0,0,0}; colorFocused[] = {0,0,0,0}; colorShadow[] = {0,0,0,0}; colorBorder[] = {0,0,0,0}; borderSize = 0; offsetX = 0; offsetY = 0; offsetPressedX = 0; offsetPressedY = 0; colorText[] = {0,0,0,0}; };
		class sp2Btn: RscButton { idc = 1642; text = ""; x = SP_BASEX + (2 * SP_COLSTEP); y = SP_BASEY; w = SP_CARDW; h = SP_CARDH; colorBackground[] = {0,0,0,0}; colorBackgroundActive[] = {1,1,1,0.08}; colorBackgroundDisabled[] = {0,0,0,0}; colorFocused[] = {0,0,0,0}; colorShadow[] = {0,0,0,0}; colorBorder[] = {0,0,0,0}; borderSize = 0; offsetX = 0; offsetY = 0; offsetPressedX = 0; offsetPressedY = 0; colorText[] = {0,0,0,0}; };
		class sp3Btn: RscButton { idc = 1643; text = ""; x = SP_BASEX; y = SP_BASEY + SP_ROWSTEP; w = SP_CARDW; h = SP_CARDH; colorBackground[] = {0,0,0,0}; colorBackgroundActive[] = {1,1,1,0.08}; colorBackgroundDisabled[] = {0,0,0,0}; colorFocused[] = {0,0,0,0}; colorShadow[] = {0,0,0,0}; colorBorder[] = {0,0,0,0}; borderSize = 0; offsetX = 0; offsetY = 0; offsetPressedX = 0; offsetPressedY = 0; colorText[] = {0,0,0,0}; };
		class sp4Btn: RscButton { idc = 1644; text = ""; x = SP_BASEX + SP_COLSTEP; y = SP_BASEY + SP_ROWSTEP; w = SP_CARDW; h = SP_CARDH; colorBackground[] = {0,0,0,0}; colorBackgroundActive[] = {1,1,1,0.08}; colorBackgroundDisabled[] = {0,0,0,0}; colorFocused[] = {0,0,0,0}; colorShadow[] = {0,0,0,0}; colorBorder[] = {0,0,0,0}; borderSize = 0; offsetX = 0; offsetY = 0; offsetPressedX = 0; offsetPressedY = 0; colorText[] = {0,0,0,0}; };
		class sp5Btn: RscButton { idc = 1645; text = ""; x = SP_BASEX + (2 * SP_COLSTEP); y = SP_BASEY + SP_ROWSTEP; w = SP_CARDW; h = SP_CARDH; colorBackground[] = {0,0,0,0}; colorBackgroundActive[] = {1,1,1,0.08}; colorBackgroundDisabled[] = {0,0,0,0}; colorFocused[] = {0,0,0,0}; colorShadow[] = {0,0,0,0}; colorBorder[] = {0,0,0,0}; borderSize = 0; offsetX = 0; offsetY = 0; offsetPressedX = 0; offsetPressedY = 0; colorText[] = {0,0,0,0}; };
		class sp6Btn: RscButton { idc = 1646; text = ""; x = SP_BASEX; y = SP_BASEY + (2 * SP_ROWSTEP); w = SP_CARDW; h = SP_CARDH; colorBackground[] = {0,0,0,0}; colorBackgroundActive[] = {1,1,1,0.08}; colorBackgroundDisabled[] = {0,0,0,0}; colorFocused[] = {0,0,0,0}; colorShadow[] = {0,0,0,0}; colorBorder[] = {0,0,0,0}; borderSize = 0; offsetX = 0; offsetY = 0; offsetPressedX = 0; offsetPressedY = 0; colorText[] = {0,0,0,0}; };
		class sp7Btn: RscButton { idc = 1647; text = ""; x = SP_BASEX + SP_COLSTEP; y = SP_BASEY + (2 * SP_ROWSTEP); w = SP_CARDW; h = SP_CARDH; colorBackground[] = {0,0,0,0}; colorBackgroundActive[] = {1,1,1,0.08}; colorBackgroundDisabled[] = {0,0,0,0}; colorFocused[] = {0,0,0,0}; colorShadow[] = {0,0,0,0}; colorBorder[] = {0,0,0,0}; borderSize = 0; offsetX = 0; offsetY = 0; offsetPressedX = 0; offsetPressedY = 0; colorText[] = {0,0,0,0}; };
		class sp8Btn: RscButton { idc = 1648; text = ""; x = SP_BASEX + (2 * SP_COLSTEP); y = SP_BASEY + (2 * SP_ROWSTEP); w = SP_CARDW; h = SP_CARDH; colorBackground[] = {0,0,0,0}; colorBackgroundActive[] = {1,1,1,0.08}; colorBackgroundDisabled[] = {0,0,0,0}; colorFocused[] = {0,0,0,0}; colorShadow[] = {0,0,0,0}; colorBorder[] = {0,0,0,0}; borderSize = 0; offsetX = 0; offsetY = 0; offsetPressedX = 0; offsetPressedY = 0; colorText[] = {0,0,0,0}; };

		// Declared last: on top of the click targets, so nothing can paint over them.
		class sp0Label: RscText { idc = 1620; text = "$STR_TIA_Style_FieldMedallion"; x = SP_BASEX; y = SP_BASEY; w = SP_CARDW; h = SP_CARDH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95,0.93,0.86,1}; style = ST_CENTER; font = "PuristaBold"; sizeEx = 0.022 * safezoneH; shadow = 1; };
		class sp1Label: RscText { idc = 1621; text = "$STR_TIA_Style_StruckCoin"; x = SP_BASEX + SP_COLSTEP; y = SP_BASEY; w = SP_CARDW; h = SP_CARDH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95,0.93,0.86,1}; style = ST_CENTER; font = "PuristaBold"; sizeEx = 0.022 * safezoneH; shadow = 1; };
		class sp2Label: RscText { idc = 1622; text = "$STR_TIA_Style_EnamelPin"; x = SP_BASEX + (2 * SP_COLSTEP); y = SP_BASEY; w = SP_CARDW; h = SP_CARDH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95,0.93,0.86,1}; style = ST_CENTER; font = "PuristaBold"; sizeEx = 0.022 * safezoneH; shadow = 1; };
		class sp3Label: RscText { idc = 1623; text = "$STR_TIA_Style_DogTag"; x = SP_BASEX; y = SP_BASEY + SP_ROWSTEP; w = SP_CARDW; h = SP_CARDH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95,0.93,0.86,1}; style = ST_CENTER; font = "PuristaBold"; sizeEx = 0.022 * safezoneH; shadow = 1; };
		class sp4Label: RscText { idc = 1624; text = "$STR_TIA_Style_UnitPatch"; x = SP_BASEX + SP_COLSTEP; y = SP_BASEY + SP_ROWSTEP; w = SP_CARDW; h = SP_CARDH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95,0.93,0.86,1}; style = ST_CENTER; font = "PuristaBold"; sizeEx = 0.022 * safezoneH; shadow = 1; };
		class sp5Label: RscText { idc = 1625; text = "$STR_TIA_Style_CrateStencil"; x = SP_BASEX + (2 * SP_COLSTEP); y = SP_BASEY + SP_ROWSTEP; w = SP_CARDW; h = SP_CARDH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95,0.93,0.86,1}; style = ST_CENTER; font = "PuristaBold"; sizeEx = 0.022 * safezoneH; shadow = 1; };
		class sp6Label: RscText { idc = 1626; text = "$STR_TIA_Style_CaseFile"; x = SP_BASEX; y = SP_BASEY + (2 * SP_ROWSTEP); w = SP_CARDW; h = SP_CARDH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95,0.93,0.86,1}; style = ST_CENTER; font = "PuristaBold"; sizeEx = 0.022 * safezoneH; shadow = 1; };
		class sp7Label: RscText { idc = 1627; text = "$STR_TIA_Style_ChalkMark"; x = SP_BASEX + SP_COLSTEP; y = SP_BASEY + (2 * SP_ROWSTEP); w = SP_CARDW; h = SP_CARDH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95,0.93,0.86,1}; style = ST_CENTER; font = "PuristaBold"; sizeEx = 0.022 * safezoneH; shadow = 1; };
		class sp8Label: RscText { idc = 1628; text = "$STR_TIA_Style_EvidenceTag"; x = SP_BASEX + (2 * SP_COLSTEP); y = SP_BASEY + (2 * SP_ROWSTEP); w = SP_CARDW; h = SP_CARDH; colorBackground[] = {0,0,0,0}; colorText[] = {0.95,0.93,0.86,1}; style = ST_CENTER; font = "PuristaBold"; sizeEx = 0.022 * safezoneH; shadow = 1; };
		// Colourblind-safe palette toggle - Waldo_accessibilityMode in
		// profileNamespace, read by Waldo_roleColor itself (fn_initShops.sqf),
		// so this one toggle covers every caller of that function (HUD, buy
		// menu, top bar icons, radar, ping wheel) without needing its own
		// per-system switch. Text/state set in script on open and on click.
		// Bottom-left corner, clear of the card grid above it.
		class spAccessToggle: RscButton {
			idc = 1592;
			text = "";
			x = safezoneX + (0.325 * safezoneW);
			y = safezoneY + (0.80 * safezoneH);
			w = 0.15 * safezoneW;
			h = 0.04 * safezoneH;
			colorBackground[] = WALDO_BTN;
			colorBackgroundActive[] = WALDO_BTNACTIVE;
			colorText[] = {0.95,0.93,0.86,1};
			sizeEx = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.85);
		};
		class spClose: RscButton {
			idc = 1599;
			text = "$STR_TIA_Ui_CloseEsc";
			x = safezoneX + (0.575 * safezoneW);
			y = safezoneY + (0.80 * safezoneH);
			w = 0.10 * safezoneW;
			h = 0.04 * safezoneH;
			colorBackground[] = WALDO_BTN;
			colorBackgroundActive[] = WALDO_BTNACTIVE;
			colorText[] = {0.95,0.93,0.86,1};
			sizeEx = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1);
			action = "closeDialog 1";
		};
	};
};
#undef SP_BASEX
#undef SP_BASEY
#undef SP_CARDW
#undef SP_CARDH
#undef SP_COLSTEP
#undef SP_ROWSTEP

// ============================================================================
// WaldoDebug - the dev / test menu (opened with '\' when Testing Mode is on).
// Buttons are generated at runtime from an action list by Waldo_fnc_debugMenu,
// so this shell never changes when a test tool is added or removed.
//   idc 3100 = title, 3101 = live game-state readout, 3102 = scrollable grid.
// ============================================================================
class WaldoDebug {
	idd = -1;
	fadeout = 0.15;
	fadein = 0.15;
	movingEnable = true;
	enableSimulation = true;
	duration = 99999;
	// Same modal guard as WaldoStylePicker: notification cards are created on
	// display 46 and were drawing over this mission's dialogs instead of under
	// them. Flag while open so Waldo_fnc_ShowUiNotification queues, and drain on
	// close so nothing is lost.
	onLoad = "with uiNamespace do { WaldoDebug = _this select 0 }; uiNamespace setVariable ['Waldo_uiModalOpen', true];";
	onUnload = "uiNamespace setVariable ['Waldo_uiModalOpen', false]; [] spawn Waldo_fnc_DrainUiNotificationQueue;";

	class controlsBackground {
		class dbgDim: RscText {
			idc = -1;
			x = safezoneX; y = safezoneY; w = safezoneW; h = safezoneH;
			colorBackground[] = WALDO_DIM;
			style = 0;
		};
		class dbgShadow: RscText {
			idc = -1;
			x = (safezoneX + (0.28 * safezoneW)) - (0.006 * safezoneW);
			y = (safezoneY + (0.14 * safezoneH)) - (0.006 * safezoneH);
			w = (0.44 * safezoneW) + (0.012 * safezoneW);
			h = (0.72 * safezoneH) + (0.012 * safezoneH);
			colorBackground[] = WALDO_SHADOW;
			style = 0;
		};
		class dbgBG: RscText {
			idc = -1;
			x = (safezoneX + (0.28 * safezoneW));
			y = (safezoneY + (0.14 * safezoneH));
			w = 0.44 * safezoneW;
			h = 0.72 * safezoneH;
			colorBackground[] = WALDO_CASING;
			colorText[] = {0.95,0.93,0.86,1};
			style = 0;
			font = "PuristaMedium";
			sizeEx = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1);
		};
		class dbgHeader: RscText {
			idc = -1;
			x = (safezoneX + (0.28 * safezoneW));
			y = (safezoneY + (0.14 * safezoneH));
			w = 0.44 * safezoneW;
			h = 0.06 * safezoneH;
			colorBackground[] = WALDO_HEADERBG;
			style = 0;
		};
		class dbgAccentBar: RscText {
			idc = -1;
			x = (safezoneX + (0.28 * safezoneW));
			y = (safezoneY + (0.14 * safezoneH)) + (0.06 * safezoneH);
			w = 0.44 * safezoneW;
			h = 0.006 * safezoneH;
			colorBackground[] = WALDO_ACCENT;
			style = 0;
		};
		class dbgTitle: RscText {
			idc = 3100;
			text = "Dev / Test Menu";
			x = (safezoneX + (0.28 * safezoneW));
			y = (safezoneY + (0.14 * safezoneH));
			w = 0.44 * safezoneW;
			h = 0.06 * safezoneH;
			colorBackground[] = {0,0,0,0};
			colorText[] = {0.95,0.93,0.86,1};
			style = ST_CENTER + ST_VCENTER;
			font = "PuristaBold";
			sizeEx = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.5);
		};
		class dbgStatus: RscStructuredText {
			idc = 3101;
			text = "";
			x = (safezoneX + (0.29 * safezoneW));
			y = (safezoneY + (0.205 * safezoneH));
			w = 0.42 * safezoneW;
			h = 0.14 * safezoneH;
			size = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1);
			class Attributes {
				font = "PuristaMedium";
				color = "#F2EFE3";
				align = "left";
				shadow = 1;
			};
		};
	};

	class Controls {
		class dbgGroup: RscControlsGroup {
			idc = 3102;
			x = (safezoneX + (0.29 * safezoneW));
			y = (safezoneY + (0.35 * safezoneH));
			w = 0.42 * safezoneW;
			h = 0.50 * safezoneH;
		};
	};
};

// ============================================================================
// WaldoScore - in-round scoreboard (toggled with K). A centred panel with a
// title and a scrollable list; rows are generated at runtime by
// Waldo_fnc_scoreboard.  3301 title, 3302 scroll group, 3300 list text.
// ============================================================================
class WaldoScore {
	idd = -1;
	fadeout = 0.15;
	fadein = 0.15;
	movingEnable = false;
	enableSimulation = true;
	duration = 99999;
	// Same modal guard as WaldoStylePicker: notification cards are created on
	// display 46 and were drawing over this mission's dialogs instead of under
	// them. Flag while open so Waldo_fnc_ShowUiNotification queues, and drain on
	// close so nothing is lost.
	onLoad = "with uiNamespace do { WaldoScore = _this select 0 }; uiNamespace setVariable ['Waldo_uiModalOpen', true];";
	onUnload = "uiNamespace setVariable ['Waldo_uiModalOpen', false]; [] spawn Waldo_fnc_DrainUiNotificationQueue;";

	class controlsBackground {
		class scDim: RscText {
			idc = -1;
			x = safezoneX; y = safezoneY; w = safezoneW; h = safezoneH;
			colorBackground[] = WALDO_DIM;
			style = 0;
		};
		class scShadow: RscText {
			idc = -1;
			x = safezoneX + (0.25 * safezoneW) - (0.006 * safezoneW);
			y = safezoneY + (0.17 * safezoneH) - (0.006 * safezoneH);
			w = (0.50 * safezoneW) + (0.012 * safezoneW);
			h = (0.66 * safezoneH) + (0.012 * safezoneH);
			colorBackground[] = WALDO_SHADOW;
			style = 0;
		};
		class scBG: RscText {
			idc = -1;
			x = safezoneX + (0.25 * safezoneW);
			y = safezoneY + (0.17 * safezoneH);
			w = 0.50 * safezoneW;
			h = 0.66 * safezoneH;
			colorBackground[] = WALDO_CASING;
			style = 0;
		};
		class scTitleBar: RscText {
			idc = -1;
			x = safezoneX + (0.25 * safezoneW);
			y = safezoneY + (0.17 * safezoneH);
			w = 0.50 * safezoneW;
			h = 0.062 * safezoneH;
			colorBackground[] = WALDO_HEADERBG;
			style = 0;
		};
		class scAccentBar: RscText {
			idc = -1;
			x = safezoneX + (0.25 * safezoneW);
			y = safezoneY + (0.17 * safezoneH) + (0.062 * safezoneH);
			w = 0.50 * safezoneW;
			h = 0.006 * safezoneH;
			colorBackground[] = WALDO_ACCENT;
			style = 0;
		};
		class scTitle: RscText {
			idc = 3301;
			text = "$STR_TIA_Ui_RoundScoreboard";
			x = safezoneX + (0.25 * safezoneW);
			y = safezoneY + (0.17 * safezoneH);
			w = 0.50 * safezoneW;
			h = 0.062 * safezoneH;
			colorText[] = {0.95,0.93,0.86,1};
			style = ST_CENTER + ST_VCENTER;
			font = "PuristaBold";
			sizeEx = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.4);
			shadow = 1;
		};

		// Keybind reference panel, attached to the scoreboard's right edge (same
		// top/height, small gap after its 0.75W right edge). Populated at runtime
		// by Waldo_fnc_scoreboard from the same Waldo_keyHintsFor helper the top
		// bar uses, so both stay in sync with a single source of truth.
		class scKbShadow: RscText {
			idc = -1;
			x = (safezoneX + (0.756 * safezoneW)) - (0.006 * safezoneW);
			y = safezoneY + (0.17 * safezoneH) - (0.006 * safezoneW);
			w = (0.16 * safezoneW) + (0.012 * safezoneW);
			h = (0.66 * safezoneH) + (0.012 * safezoneW);
			colorBackground[] = WALDO_SHADOW;
			style = 0;
		};
		class scKbBG: RscText {
			idc = -1;
			x = safezoneX + (0.756 * safezoneW);
			y = safezoneY + (0.17 * safezoneH);
			w = 0.16 * safezoneW;
			h = 0.66 * safezoneH;
			colorBackground[] = WALDO_CASING;
			style = 0;
		};
		// "Your Briefing" (top ~half of this column) - who you are and who
		// you're actually supposed to know about this round, the same
		// content the round-start card showed (Waldo_fnc_showRoleCard),
		// re-viewable here any time via Waldo_fnc_roleBriefingText so a
		// missed/expired notification doesn't lose it for the round.
		// Keybinds (below) shrinks to make room rather than growing the
		// whole column - this side panel's total footprint (scKbShadow/
		// scKbBG above) stays exactly what it was.
		class scBriefHeaderBG: RscText {
			idc = -1;
			x = safezoneX + (0.756 * safezoneW);
			y = safezoneY + (0.17 * safezoneH);
			w = 0.16 * safezoneW;
			h = 0.045 * safezoneH;
			colorBackground[] = WALDO_HEADERBG;
			style = 0;
		};
		class scBriefAccent: RscText {
			idc = -1;
			x = safezoneX + (0.756 * safezoneW);
			y = safezoneY + (0.17 * safezoneH) + (0.045 * safezoneH);
			w = 0.16 * safezoneW;
			h = 0.004 * safezoneH;
			colorBackground[] = WALDO_ACCENT;   // tinted to the viewer's own role colour at runtime
			style = 0;
		};
		class scBriefTitle: RscText {
			idc = -1;
			text = "$STR_TIA_Ui_YourBriefing";
			x = safezoneX + (0.756 * safezoneW);
			y = safezoneY + (0.17 * safezoneH);
			w = 0.16 * safezoneW;
			h = 0.045 * safezoneH;
			colorText[] = {0.95,0.93,0.86,1};
			style = ST_CENTER;
			font = "PuristaBold";
			sizeEx = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.0);
			shadow = 1;
		};
		class scBriefList: RscStructuredText {
			idc = 3330;
			text = "";
			x = safezoneX + (0.756 * safezoneW) + (0.010 * safezoneW);
			y = safezoneY + (0.17 * safezoneH) + (0.052 * safezoneH);
			w = (0.16 * safezoneW) - (0.020 * safezoneW);
			h = 0.26 * safezoneH;
			size = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.85);
			class Attributes {
				font = "PuristaMedium";
				color = "#D8D5C8";
				align = "left";
				shadow = 1;
			};
		};
		class scKbHeaderBG: RscText {
			idc = -1;
			x = safezoneX + (0.756 * safezoneW);
			y = safezoneY + (0.17 * safezoneH) + (0.332 * safezoneH);
			w = 0.16 * safezoneW;
			h = 0.045 * safezoneH;
			colorBackground[] = WALDO_HEADERBG;
			style = 0;
		};
		class scKbAccent: RscText {
			idc = -1;
			x = safezoneX + (0.756 * safezoneW);
			y = safezoneY + (0.17 * safezoneH) + (0.377 * safezoneH);
			w = 0.16 * safezoneW;
			h = 0.004 * safezoneH;
			colorBackground[] = WALDO_ACCENT;
			style = 0;
		};
		class scKbTitle: RscText {
			idc = -1;
			text = "$STR_TIA_Ui_Keybinds";
			x = safezoneX + (0.756 * safezoneW);
			y = safezoneY + (0.17 * safezoneH) + (0.332 * safezoneH);
			w = 0.16 * safezoneW;
			h = 0.045 * safezoneH;
			colorText[] = {0.95,0.93,0.86,1};
			style = ST_CENTER;
			font = "PuristaBold";
			sizeEx = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.05);
			shadow = 1;
		};
		class scKbList: RscStructuredText {
			idc = 3320;
			text = "";
			x = safezoneX + (0.756 * safezoneW) + (0.010 * safezoneW);
			y = safezoneY + (0.17 * safezoneH) + (0.385 * safezoneH);
			w = (0.16 * safezoneW) - (0.020 * safezoneW);
			h = 0.265 * safezoneH;
			size = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.9);
			class Attributes {
				font = "PuristaMedium";
				color = "#D8D5C8";
				align = "left";
				shadow = 1;
			};
		};
	};

	class Controls {
		class scGroup: RscControlsGroup {
			idc = 3302;
			x = safezoneX + (0.26 * safezoneW);
			y = safezoneY + (0.245 * safezoneH);
			w = 0.48 * safezoneW;
			h = 0.52 * safezoneH;

			class Controls {
				class scList: RscStructuredText {
					idc = 3300;
					text = "";
					x = 0;
					y = 0;
					w = 0.46 * safezoneW;
					h = 3.0 * safezoneH;   // tall so the group scrolls for big lobbies
					size = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1);
					class Attributes {
						font = "PuristaMedium";
						color = "#F2EFE3";
						align = "left";
						shadow = 1;
					};
				};
			};
		};
		class scClose: RscButton {
			idc = 2;
			text = "$STR_TIA_Ui_CloseK";
			x = safezoneX + (0.64 * safezoneW);
			y = safezoneY + (0.785 * safezoneH);
			w = 0.10 * safezoneW;
			h = 0.038 * safezoneH;
			colorBackground[] = WALDO_BTN;
			colorBackgroundActive[] = WALDO_BTNACTIVE;
			colorText[] = {0.95,0.93,0.86,1};
			sizeEx = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1);
			action = "closeDialog 1";
		};
	};
};

// ============================================================================
// WaldoDisguise - the Traitor "Disguiser" item's target picker
// (Waldo_fnc_disguiserOpen). Same shell recipe as WaldoScore/WaldoShop (dim,
// shadow, casing, header, accent stripe, title, close button), scaled down
// since it only needs one scrollable list of player buttons - generated at
// runtime the same way WaldoShop's item grid is, so this shell never changes
// when the player list does.
//   3800 title, 3801 button group (buttons themselves are ctrlCreate'd at
//   3820+i by Waldo_fnc_disguiserOpen), idc 2 close/cancel (shared
//   convention with every other Waldo dialog's close button).
// ============================================================================
class WaldoDisguise {
	idd = -1;
	fadeout = 0.15;
	fadein = 0.15;
	movingEnable = false;
	enableSimulation = true;
	duration = 99999;
	// Same modal guard as every other Waldo dialog - notification cards draw
	// on display 46, over this dialog otherwise, so queue them while open and
	// drain on close.
	onLoad = "with uiNamespace do { WaldoDisguise = _this select 0 }; uiNamespace setVariable ['Waldo_uiModalOpen', true];";
	onUnload = "uiNamespace setVariable ['Waldo_uiModalOpen', false]; [] spawn Waldo_fnc_DrainUiNotificationQueue;";

	class controlsBackground {
		class wdDim: RscText {
			idc = -1;
			x = safezoneX; y = safezoneY; w = safezoneW; h = safezoneH;
			colorBackground[] = WALDO_DIM;
			style = 0;
		};
		class wdShadow: RscText {
			idc = -1;
			x = (safezoneX + (0.35 * safezoneW)) - (0.006 * safezoneW);
			y = (safezoneY + (0.22 * safezoneH)) - (0.006 * safezoneW);
			w = (0.30 * safezoneW) + (0.012 * safezoneW);
			h = (0.56 * safezoneH) + (0.012 * safezoneW);
			colorBackground[] = WALDO_SHADOW;
			style = 0;
		};
		class wdBG: RscText {
			idc = -1;
			x = safezoneX + (0.35 * safezoneW);
			y = safezoneY + (0.22 * safezoneH);
			w = 0.30 * safezoneW;
			h = 0.56 * safezoneH;
			colorBackground[] = WALDO_CASING;
			style = 0;
		};
		class wdHeader: RscText {
			idc = -1;
			x = safezoneX + (0.35 * safezoneW);
			y = safezoneY + (0.22 * safezoneH);
			w = 0.30 * safezoneW;
			h = 0.062 * safezoneH;
			colorBackground[] = WALDO_HEADERBG;
			style = 0;
		};
		class wdAccentBar: RscText {
			idc = -1;
			x = safezoneX + (0.35 * safezoneW);
			y = (safezoneY + (0.22 * safezoneH)) + (0.062 * safezoneH);
			w = 0.30 * safezoneW;
			h = 0.006 * safezoneH;
			colorBackground[] = WALDO_ACCENT;   // Traitor-only item, so effectively fixed red
			style = 0;
		};
		class wdTitle: RscText {
			idc = 3800;
			text = "$STR_TIA_Ui_DisguiseAs";
			x = safezoneX + (0.35 * safezoneW);
			y = safezoneY + (0.22 * safezoneH);
			w = 0.30 * safezoneW;
			h = 0.062 * safezoneH;
			colorBackground[] = {0,0,0,0};
			colorText[] = {0.95,0.93,0.86,1};
			style = ST_CENTER + ST_VCENTER;
			font = "PuristaBold";
			sizeEx = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1.4);
			shadow = 1;
		};
	};

	class Controls {
		class wdGroup: RscControlsGroup {
			idc = 3801;
			x = safezoneX + (0.36 * safezoneW);
			y = safezoneY + (0.30 * safezoneH);
			w = 0.28 * safezoneW;
			h = 0.40 * safezoneH;

			class Controls {
				// Same fixed-tall-spacer trick as WaldoShop's shopPurchSpacer -
				// forces the group's scrollable extent for a runtime-created
				// (ctrlCreate) child list, since that isn't computed from
				// children added after dialog load the way a single declared
				// oversized child (WaldoScore's scList) is. Pushed off past the
				// button rows' own right edge (0 to 0.26*safezoneW locally) so
				// it never sits on top of anything clickable.
				class wdSpacer: RscStructuredText {
					idc = -1;
					text = "";
					x = 0.271 * safezoneW;
					y = 0;
					w = 0.001 * safezoneW;
					h = 2.0 * safezoneH;
				};
			};
		};
		class wdClose: RscButton {
			idc = 2;
			text = "$STR_TIA_Ui_CancelEsc";
			x = safezoneX + (0.44 * safezoneW);
			y = safezoneY + (0.72 * safezoneH);
			w = 0.12 * safezoneW;
			h = 0.04 * safezoneH;
			colorBackground[] = WALDO_BTN;
			colorBackgroundActive[] = WALDO_BTNACTIVE;
			colorText[] = {0.95,0.93,0.86,1};
			sizeEx = (((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1);
			action = "closeDialog 1";
		};
	};
};
