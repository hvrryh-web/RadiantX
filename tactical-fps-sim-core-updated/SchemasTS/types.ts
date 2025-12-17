export type TeamSide = "Attack" | "Defend";

export type Vec2 = { x: number; y: number };

export type UtilityFamily = "CS_Grenade" | "VAL_Ability";
export type FireMode = "Semi" | "Burst" | "Auto";
export type CastType = "ThrowArc" | "FireProjectile" | "InstantAOE" | "PlaceMarker" | "Beam" | "Self";

export type RulesetDef = {
  id: string;
  utilityFamily: UtilityFamily;
  maxGrenades?: number;
  usesAbilityEconomy?: boolean;
  roundStartCredits?: number;
  maxCredits?: number;
  roundWinCredits?: number;
  roundLossCredits?: number;
  killCredits?: number;
  lossStreakBonuses?: number[];
  resetHpEachRound?: boolean;
  resetArmorEachRound?: boolean;
  refillSignatureEachRound?: boolean;
  defaultSignatureRoundStartCharges?: number;
};

export type TraitBlock = {
  aim: number; recoilControl: number; reaction: number; movement: number;
  gameSense: number; composure: number; teamwork: number; utility: number;
  discipline: number; aggression: number;
};

export type AgentDef = {
  id: string;
  displayName: string;
  baseHp: number;
  baseArmor?: number;
  traits: TraitBlock;
  loadoutWeaponIds: string[];
  loadoutUtilityIds: string[];
};

export type WeaponDef = {
  id: string;
  fireMode: FireMode;
  creditCost?: number;
  magazineSize: number;
  roundsPerMinute: number;
  reloadTime: number;
  damage: {
    baseDamage: number;
    headMult: number;
    legMult: number;
    rangeMultiplierKeys: Array<{ x: number; y: number }>;
  };
  spread: {
    baseSigma: number;
    crouchMult: number;
    moveSigmaAdd: number;
    jumpSigmaAdd: number;
    firstShotBonus: number;
  };
  recoil: {
    recoilPerShot: number;
    maxRecoil: number;
    recoveryPerSec: number;
  };
  penetration: {
    canPenetrate: boolean;
    penPower: number;
    damageLossPerUnit: number;
  };
};

export type UtilityDef = {
  id: string;
  family: UtilityFamily;
  castType: CastType;
  equipTime: number;
  castTime: number;
  maxCharges: number;
  cooldown?: number;
  creditCost?: number;
  isSignature?: boolean;
  roundStartCharges?: number;
  throw?: { speed: number; gravity: number; fuseTime: number; detonateOnRest: boolean };
  projectile?: { speed: number; gravity: number; maxLife: number; bounces: boolean; bounceDamp: number };
  effects: Array<{
    kind:
      | "Smoke" | "FlashBlind" | "Concuss" | "Slow" | "Burn" | "Heal" | "Shield"
      | "Reveal" | "Suppress" | "Knockback" | "Wall" | "Trap" | "DecoySound" | "Explosion";
    duration: number;
    radius: number;
    dpsOrValue: number;
    falloff: number;
    requiresLOS: boolean;
    requiresFacing: boolean;
    facingAngleDeg: number;
  }>;
};

export type MapDef = {
  id: string;
  name: string;
  walls: Array<{ ax: number; ay: number; bx: number; by: number }>;
};
