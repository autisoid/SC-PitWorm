void PluginInit() {
    g_Module.ScriptInfo.SetAuthor("xWhitey");
    g_Module.ScriptInfo.SetContactInfo("tyabus @ Discord");
}

void MapInit() {
    g_CustomEntityFuncs.RegisterCustomEntity("COFPitWormUp", "monster_pitworm_up");
    g_CustomEntityFuncs.RegisterCustomEntity("COFPitWormSteamTrigger", "info_pitworm_steam_lock");
}

float g_flPitWormHealth = 100.f; //HARD level health
//float g_flPitWormSwipe = 50.f; //HARD level swipe damage <-- That wasn't used in the original game? I dunno. ~ xWhitey
float g_flPitWormBeam = 20.f; //HARD level beam damage

size_t PITWORM_UP_AE_HITGROUND = 1;
size_t PITWORM_UP_AE_SHOOTBEAM = 2;
size_t PITWORM_UP_AE_LOCKYAW = 4;

enum PITWORMUP_ANIM
{
    PITWORM_ANIM_IdleLong = 0,
    PITWORM_ANIM_IdleShort,
    PITWORM_ANIM_Level2AttackCenter,
    PITWORM_ANIM_Scream,
    PITWORM_ANIM_Level1AttackCenter,
    PITWORM_ANIM_Level2AttackLeft,
    PITWORM_ANIM_Level1AttackRight,
    PITWORM_ANIM_Level1AttackLeft,
    PITWORM_ANIM_RangeAttack,
    PITWORM_ANIM_Level3Attack1,
    PITWORM_ANIM_Level3Attack2,
    PITWORM_ANIM_Flinch1,
    PITWORM_ANIM_Flinch2,
    PITWORM_ANIM_Death,
}

size_t PITWORM_UP_NUM_LEVELS = 4;
size_t PITWORM_UP_EYE_HEIGHT = 300.0f;

array<float> PITWORM_UP_LEVELS =
    {
        PITWORM_UP_EYE_HEIGHT,
        PITWORM_UP_EYE_HEIGHT,
        PITWORM_UP_EYE_HEIGHT,
        PITWORM_UP_EYE_HEIGHT + 50}; //sizeof == PITWORM_UP_NUM_LEVELS
        
array<string> PITWORM_UP_LEVEL_NAMES =
    {
        "pw_tleveldead",
        "pw_tlevel1",
        "pw_tlevel2",
        "pw_tlevel3"}; //sizeof == PITWORM_UP_NUM_LEVELS

array<string> g_rgpszAttackSounds =
    {
        "hlcancer/generic/zombie/claw_strike1.wav",
        "hlcancer/generic/zombie/claw_strike2.wav",
        "hlcancer/generic/zombie/claw_strike3.wav"};

array<string> g_rgpszAttackVoiceSounds =
    {
        "hlcancer/op4/pitworm/pit_worm_attack_swipe1.wav",
        "hlcancer/op4/pitworm/pit_worm_attack_swipe2.wav",
        "hlcancer/op4/pitworm/pit_worm_attack_swipe3.wav"};

array<string> g_rgpszShootSounds =
    {
        "hlcancer/generic/debris/beamstart3.wav",
        "hlcancer/generic/debris/beamstart8.wav"};

array<string> g_rgpszPainSounds =
    {
        "hlcancer/op4/pitworm/pit_worm_flinch1.wav",
        "hlcancer/op4/pitworm/pit_worm_flinch2.wav"};

array<string> g_rgpszHitGroundSounds =
    {
        "hlcancer/generic/tentacle/te_strike1.wav",
        "hlcancer/generic/tentacle/te_strike2.wav"};

array<string> g_rgpszIdleSounds =
    {
        "hlcancer/op4/pitworm/pit_worm_idle1.wav",
        "hlcancer/op4/pitworm/pit_worm_idle2.wav",
        "hlcancer/op4/pitworm/pit_worm_idle3.wav"};
        
void PrecacheSound(const string& in _SoundName) {
    g_Game.PrecacheGeneric("sound/" + _SoundName);
    g_SoundSystem.PrecacheSound(_SoundName);
}

void PrecacheSoundArray(array<string>@ _Sounds) {
    for (uint idx = 0; idx < _Sounds.length(); idx++) {
        g_Game.PrecacheGeneric("sound/" + _Sounds[idx]);
        g_SoundSystem.PrecacheSound(_Sounds[idx]);
    }
}

float fabsf(float _Value) {
    return _Value < 0.f ? (_Value * -1.f) : _Value;
}

class COFPitWormUp : ScriptBaseMonsterEntity {
    COFPitWormUp() {
        //m_flPreviousFrame = -1.f;
    
        m_flLevels.resize(0);
        m_flLevels.resize(PITWORM_UP_NUM_LEVELS);
        m_flTargetLevels.resize(0);
        m_flTargetLevels.resize(PITWORM_UP_NUM_LEVELS);
    }

    void Precache() {
        BaseClass.Precache();
        g_Game.PrecacheModel("models/hlcancer/opfor/pit_worm_up.mdl");
        g_Game.PrecacheModel("sprites/hlcancer/generic/tele1.spr");
        g_Game.PrecacheModel("sprites/laserbeam.spr");

        PrecacheSoundArray(g_rgpszAttackSounds);
        PrecacheSoundArray(g_rgpszAttackVoiceSounds);
        PrecacheSoundArray(g_rgpszShootSounds);
        PrecacheSoundArray(g_rgpszPainSounds);
        PrecacheSoundArray(g_rgpszHitGroundSounds);
        PrecacheSoundArray(g_rgpszIdleSounds);

        PrecacheSound("hlcancer/generic/debris/beamstart7.wav");

        PrecacheSound("hlcancer/op4/pitworm/clang1.wav");
        PrecacheSound("hlcancer/op4/pitworm/clang2.wav");
        PrecacheSound("hlcancer/op4/pitworm/clang3.wav");

        PrecacheSound("hlcancer/op4/pitworm/pit_worm_alert.wav");

        PrecacheSound("hlcancer/op4/pitworm/pit_worm_attack_eyeblast.wav");
        PrecacheSound("hlcancer/op4/pitworm/pit_worm_attack_eyeblast_impact.wav");

        PrecacheSound("hlcancer/op4/pitworm/pit_worm_attack_swipe1.wav");
        PrecacheSound("hlcancer/op4/pitworm/pit_worm_attack_swipe2.wav");
        PrecacheSound("hlcancer/op4/pitworm/pit_worm_attack_swipe3.wav");

        PrecacheSound("hlcancer/op4/pitworm/pit_worm_death.wav");

        PrecacheSound("hlcancer/op4/pitworm/pit_worm_flinch1.wav");
        PrecacheSound("hlcancer/op4/pitworm/pit_worm_flinch2.wav");
    }
    
    void SetObjectCollisionBox()
    {
        self.pev.absmin = self.pev.origin + Vector(-400, -400, 0);
        self.pev.absmax = self.pev.origin + Vector(400, 400, 850);
    }
    
    void GibMonster() {
    
    }
    
    void Spawn() {
        BaseClass.Spawn();
        Precache();
        
        self.pev.movetype = MOVETYPE_FLY;
        self.pev.solid = SOLID_BBOX;

        g_EntityFuncs.SetModel(self, "models/hlcancer/opfor/pit_worm_up.mdl");

        g_EntityFuncs.SetSize(self.pev, Vector(-400, -400, 0), Vector(400, 400, 850));

        g_EntityFuncs.SetOrigin(self, self.pev.origin);

        self.pev.flags |= FL_MONSTER;
        self.pev.takedamage = DAMAGE_AIM;

        self.pev.max_health = self.pev.health = g_flPitWormHealth;

        self.pev.view_ofs = Vector(0, 0, PITWORM_UP_EYE_HEIGHT);

        self.m_bloodColor = BLOOD_COLOR_GREEN;
        self.m_flFieldOfView = 0.5;
        self.m_FormattedName = "Pit Worm";

        self.pev.sequence = 0;

        // Force interpolation on.
        //m_EFlags |= EFLAG_SLERP;
        
        CBaseMonster@ pSelfMonster = cast<CBaseMonster@>(self);
        pSelfMonster.ResetSequenceInfo();

        m_flTorsoYaw = 0;
        m_flHeadYaw = 0;
        m_flHeadPitch = 0;
        m_flIdealTorsoYaw = 0;
        m_flIdealHeadYaw = 0;
        m_flIdealHeadPitch = 0;

        pSelfMonster.InitBoneControllers();

        SetThink(ThinkFunction(StartupThink));
        SetTouch(TouchFunction(HitTouch));

        self.pev.nextthink = g_Engine.time + 0.1;

        m_vecDesired = Vector(1, 0, 0);

        m_posDesired = self.pev.origin;

        m_fAttacking = false;
        m_fLockHeight = false;
        m_fFirstSighting = false;

        m_flBeamExpireTime = g_Engine.time;

        m_iLevel = 0;
        m_fLockYaw = false;
        m_iWasHit = 0;

        m_flTakeHitTime = 0;
        m_flHitTime = 0;
        m_flLevelSpeed = 10;

        m_fTopLevelLocked = false;
        m_flLastBlinkTime = g_Engine.time;
        m_flLastBlinkInterval = g_Engine.time;
        m_flLastEventTime = g_Engine.time;
        
        m_bDeadFlag = false;

        for (size_t i = 0; i < PITWORM_UP_NUM_LEVELS; ++i)
        {
            m_flLevels[i] = self.pev.origin.z - PITWORM_UP_LEVELS[i];
        }
        
        for (size_t i = 0; i < PITWORM_UP_NUM_LEVELS; ++i) {
            m_flTargetLevels[i] = self.pev.origin.z;
        }

        @m_pBeam = null;
    }
    
    void StartupThink() {
        for (size_t i = 0; i < PITWORM_UP_NUM_LEVELS; ++i)
        {
            CBaseEntity@ pTarget = g_EntityFuncs.FindEntityByTargetname(null, PITWORM_UP_LEVEL_NAMES[i]);

            if (pTarget !is null)
            {
                //ALERT(at_console, "level %d node set\n", i);
                m_flTargetLevels[i] = pTarget.pev.origin.z;
                m_flLevels[i] = pTarget.pev.origin.z - PITWORM_UP_LEVELS[i];
            }
        }
        
        string pszTarget = string(self.pev.target).ToLowercase();

        if (!pszTarget.IsEmpty())
        {
            if (!m_fTopLevelLocked && pszTarget == "pw_level3")
            {
                m_iLevel = 3;
            }
            else if (pszTarget == "pw_level2")
            {
                m_iLevel = 2;
            }
            else if (pszTarget == "pw_level1")
            {
                m_iLevel = 1;
            }
            else if (pszTarget == "pw_leveldead")
            {
                m_iLevel = 0;
            }

            m_posDesired.z = m_flLevels[m_iLevel];
        }

        Vector vecEyePos, vecEyeAng;

        CBaseAnimating@ pAnimating = cast<CBaseAnimating@>(self);
        pAnimating.GetAttachment(0, vecEyePos, vecEyeAng);

        self.pev.view_ofs = vecEyePos - self.pev.origin;

        m_flNextMeleeTime = g_Engine.time;

        SetThink(ThinkFunction(HuntThink));
        SetUse(UseFunction(CommandUse));

        m_flNextRangeTime = g_Engine.time;

        self.pev.nextthink = g_Engine.time + 0.1f;
    }
    
    void NullThink() {
        self.StudioFrameAdvance();
        self.pev.nextthink = g_Engine.time + 0.5f;
    }
    
    void HuntThink() {
        CBaseAnimating@ pAnimating = cast<CBaseAnimating@>(self);
        self.pev.nextthink = g_Engine.time + 0.1;
        self.DispatchAnimEvents();
        self.StudioFrameAdvance();

        //UpdateShockEffect();

        if (m_pBeam !is null)
        {
            if (self.m_hEnemy.IsValid() && m_flBeamExpireTime > g_Engine.time)
            {
                StrafeBeam();
            }
            else
            {
                g_EntityFuncs.Remove(m_pBeam);
                g_EntityFuncs.Remove(m_pSprite);
                @m_pBeam = null;
                @m_pSprite = null;
            }
        }

        if (self.pev.health <= 0.f)
        {
            SetThink(ThinkFunction(DyingThink));
            pAnimating.m_fSequenceFinished = true;
        }
        else
        {
            const float blinkInterval = g_Engine.time - m_flLastBlinkTime;

            if (blinkInterval >= 6.0 && m_pBeam is null && blinkInterval >= Math.RandomFloat(6.0, 9.0))
            {
                self.pev.skin = 1;
                m_flLastBlinkInterval = g_Engine.time;
                m_flLastBlinkTime = g_Engine.time;
            }

            if (self.pev.skin > 0 && g_Engine.time - m_flLastBlinkInterval >= 0)
            {
                if (self.pev.skin == 5)
                    self.pev.skin = 0;
                else
                    self.pev.skin = self.pev.skin + 1;

                m_flLastBlinkInterval = g_Engine.time;
            }

            if (m_iWasHit == 1)
            {
                int iDir = 1;
                self.pev.sequence = self.FindTransition(self.pev.sequence, PITWORM_ANIM_Flinch1 + Math.RandomLong(0, 1), iDir);

                if (iDir <= 0)
                    self.pev.frame = 255;
                else
                    self.pev.frame = 0;

                self.ResetSequenceInfo();

                m_iWasHit = 0;

                PainSound();
            }
            else if (pAnimating.m_fSequenceFinished)
            {
                const int oldSequence = self.pev.sequence;

                if (m_fAttacking)
                {
                    m_fLockHeight = false;
                    m_fLockYaw = false;
                    m_fAttacking = false;
                    m_flNextMeleeTime = g_Engine.time + 0.25;
                }

                NextActivity();

                if (!pAnimating.m_fSequenceLoops || self.pev.sequence != oldSequence)
                {
                    self.pev.frame = 0;
                    self.ResetSequenceInfo();
                }
            }
            if (self.m_hEnemy.IsValid())
            {
                if (FVisible(self.m_hEnemy.GetEntity(), false))
                {
                    if (g_Engine.time - 5.0 > m_flLastSeen)
                    {
                        m_flPrevSeen = g_Engine.time;
                    }

                    m_flLastSeen = g_Engine.time;

                    m_posTarget = self.m_hEnemy.GetEntity().pev.origin;

                    m_posTarget.z += 24;

                    Vector vecEyePos, vecEyeAng;
                    self.GetAttachment(0, vecEyePos, vecEyeAng);

                    m_vecTarget = (m_posTarget - vecEyePos).Normalize();

                    m_vecDesired = m_vecTarget;
                }
            }

            if (m_posDesired.z > m_flLevels[3])
                m_posDesired.z = m_flLevels[3];

            if (m_flLevels[0] > m_posDesired.z)
                m_posDesired.z = m_flLevels[0];

            ChangeLevel();

            if (self.m_hEnemy.IsValid() && m_pBeam is null)
            {
                TrackEnemy();
            }
        }
    }
    
    void HitTouch(CBaseEntity@ pOther) {
        TraceResult tr = g_Utility.GetGlobalTrace();

        if (pOther.pev.modelindex != self.pev.modelindex && m_flHitTime <= g_Engine.time && tr.pHit !is null && /*self.pev.modelindex == tr.pHit.vars.modelindex && */pOther.pev.takedamage != DAMAGE_NO)
        {
            pOther.TakeDamage(self.pev, self.pev, 20, DMG_CRUSH | DMG_SLASH);

            pOther.pev.punchangle.z = 15;

            //TODO: maybe determine direction of velocity to apply?
            pOther.pev.velocity = pOther.pev.velocity + Vector(0, 0, 200); //can be simplified - xWhitey

            pOther.pev.flags &= ~FL_ONGROUND;

            g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_WEAPON, g_rgpszAttackSounds[Math.RandomLong(0, 2)], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(-5, 5) + 100);

            if (tr.iHitgroup == 2)
                pOther.TakeDamage(self.pev, self.pev, 10, DMG_CRUSH | DMG_SLASH);

            m_flHitTime = g_Engine.time + 1.0;
        }
    }
    
    void SUB_Remove() {
        g_EntityFuncs.Remove(self);
    }
    
    void DyingThink()
    {
        self.pev.nextthink = g_Engine.time + 0.1;
        
        //self.pev.framerate = 0.5f;

        self.DispatchAnimEvents();
        self.StudioFrameAdvance(0.1f);
        
        self.pev.health = 13371337.f;
        
        //self.pev.framerate = 0.5f;
        
        if (m_flDeathStartTime == 0.f) {
            m_flDeathStartTime = g_Engine.time;
        }
        
        if (g_Engine.time - m_flDeathStartTime > 10.0) {
            ChangeLevel();
            SetThink(ThinkFunction(SUB_Remove));
            self.pev.nextthink = g_Engine.time + 0.5;
            return;
        }

        if (m_bDeadFlag)
        {
            //if (self.pev.deadflag == DEAD_DYING)
            //{
                if (g_Engine.time - m_flDeathStartTime > 3.0)
                {
                    ChangeLevel();
                }

                if (fabsf(self.pev.origin.z - m_flLevels[0]) < 16.f)
                {
                    self.pev.velocity = g_vecZero;
                    self.pev.deadflag = DEAD_DEAD;

                    SetThink(ThinkFunction(SUB_Remove));
                    self.pev.nextthink = g_Engine.time + 0.1;
                }
            //}
        }
        else
        {
            m_bDeadFlag = true;

            m_posDesired.z = m_flLevels[0];

            int iDir = 1;
            self.pev.sequence = self.FindTransition(self.pev.sequence, PITWORM_ANIM_Death, iDir);

            if (iDir <= 0)
                self.pev.frame = 255;
            else
                self.pev.frame = 0;

            //self.pev.framerate = 0.5f;
            self.ResetSequenceInfo();

            m_flLevelSpeed = 5;

            //ClearShockEffect(); //?

            g_SoundSystem.EmitSound(self.edict(), CHAN_VOICE, "hlcancer/op4/pitworm/pit_worm_death.wav", VOL_NORM, 0.1);

            m_flDeathStartTime = g_Engine.time;

            if (m_pBeam !is null)
            {
                g_EntityFuncs.Remove(m_pBeam);
                @m_pBeam = null;
            }

            if (m_pSprite !is null)
            {
                g_EntityFuncs.Remove(m_pSprite);
                @m_pSprite = null;
            }

            SetTouch(null);
            SetUse(null);
        }
    }
    
    void CommandUse(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value) {
        switch (useType)
        {
        case USE_ON:
            if (pActivator !is null) {
                CSoundEnt@ soundEnt = GetSoundEntInstance();
                soundEnt.InsertSound(bits_SOUND_WORLD, pActivator.pev.origin, 1024, 1.0, self);
            }
            break;
        case USE_TOGGLE:
            self.pev.takedamage = DAMAGE_NO;
            SetThink(ThinkFunction(DyingThink));
            break;
        case USE_OFF:
            self.pev.takedamage = DAMAGE_NO;
            SetThink(ThinkFunction(DyingThink));
            break;
        }
    }
    
    void StartupUse(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value) {
        SetThink(ThinkFunction(HuntThink));
        self.pev.nextthink = g_Engine.time + 0.1;
        SetUse(UseFunction(CommandUse));
    }
    
    void ChangeLevel()
    {
        if (self.pev.origin.z != m_posDesired.z)
        {
            if (m_posDesired.z <= self.pev.origin.z)
            {
                self.pev.origin.z -= Math.min(m_flLevelSpeed, self.pev.origin.z - m_posDesired.z);
            }
            else
            {
                self.pev.origin.z += Math.min(m_flLevelSpeed, m_posDesired.z - self.pev.origin.z);
            }
        }

        if (m_flTorsoYaw != m_flIdealTorsoYaw)
        {
            if (m_flIdealTorsoYaw <= m_flTorsoYaw)
            {
                m_flTorsoYaw -= Math.min(5, m_flTorsoYaw - m_flIdealTorsoYaw);
            }
            else
            {
                m_flTorsoYaw += Math.min(5, m_flIdealTorsoYaw - m_flTorsoYaw);
            }

            self.SetBoneController(2, m_flTorsoYaw);
        }

        if (m_flHeadYaw != m_flIdealHeadYaw)
        {
            if (m_flIdealHeadYaw <= m_flHeadYaw)
            {
                m_flHeadYaw -= Math.min(5, m_flHeadYaw - m_flIdealHeadYaw);
            }
            else
            {
                m_flHeadYaw += Math.min(5, m_flIdealHeadYaw - m_flHeadYaw);
            }

            self.SetBoneController(0, -m_flHeadYaw);
        }

        if (m_flHeadPitch != m_flIdealHeadPitch)
        {
            if (m_flIdealHeadPitch <= m_flHeadPitch)
            {
                m_flHeadPitch -= Math.min(5, m_flHeadPitch - m_flIdealHeadPitch);
            }
            else
            {
                m_flHeadPitch += Math.min(5, m_flIdealHeadPitch - m_flHeadPitch);
            }

            self.SetBoneController(1, m_flHeadPitch);
        }
    }
    
    void LockTopLevel() {
        if (m_iLevel == 3 && !m_bDeadFlag)
        {
            self.pev.health = self.pev.max_health;
            m_iWasHit = 1;
            m_iLevel = 2;
            m_flTakeHitTime = Math.RandomLong(2, 4) + g_Engine.time;
            m_posDesired.z = m_flLevels[2];
        }

        m_fTopLevelLocked = true;
    }
    
    void IdleSound() {
        //Why g_rgpszPainSounds? Why not g_rgpszIdleSounds?
        g_SoundSystem.EmitSound(self.edict(), CHAN_VOICE, g_rgpszPainSounds[Math.RandomLong(0, g_rgpszPainSounds.length() - 1)], VOL_NORM, 0.1);
    }
    
    void PainSound() {
        if (m_flNextPainSound <= g_Engine.time)
        {
            m_flNextPainSound = Math.RandomFloat(2.f, 5.f) + g_Engine.time;

            g_SoundSystem.EmitSound(self.edict(), CHAN_VOICE, g_rgpszPainSounds[Math.RandomLong(0, g_rgpszPainSounds.length() - 1)], VOL_NORM, 0.1);
        }
    }
    
    int TakeDamage(entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType) {
        PainSound();
        return 0;
    }
    
    bool FVisible(CBaseEntity@ pEntity, bool bIgnoreGlass) {
        if ((pEntity.pev.flags & FL_NOTARGET) == 0)
        {
            if ((pev.waterlevel != WATERLEVEL_HEAD && pEntity.pev.waterlevel != WATERLEVEL_HEAD) || 0 != pEntity.pev.waterlevel)
            {
                return FVisible(pEntity.EyePosition());
            }
        }

        return false;
    }
    
    bool FVisible(const Vector& in vecOrigin) {
        Vector vecLookerOrigin, vecLookerAngle;
        CBaseAnimating@ pAnimating = cast<CBaseAnimating@>(self);
        pAnimating.GetAttachment(0, vecLookerOrigin, vecLookerAngle);

        TraceResult tr;
        g_Utility.TraceLine(vecLookerOrigin, vecOrigin, ignore_monsters, ignore_glass, self.edict(), tr);

        return tr.flFraction == 1.0f;
    }
    
    void ShootBeam() {
        if (self.m_hEnemy.IsValid())
        {
            if (m_flHeadYaw > 0)
            {
                m_flBeamDir = -1;
            }
            else
            {
                m_flBeamDir = 1;
            }

            m_offsetBeam = -m_flBeamDir * 80;

            Vector vecEyePos, vecEyeAng;
            self.GetAttachment(0, vecEyePos, vecEyeAng);

            m_vecBeam = (m_posBeam - vecEyePos).Normalize();

            m_angleBeam = Math.VecToAngles(m_vecBeam);

            Math.MakeVectors(m_angleBeam);

            m_vecBeam = g_Engine.v_forward;

            m_vecBeam.z = -m_vecBeam.z;

            TraceResult tr;
            g_Utility.TraceLine(vecEyePos, vecEyePos + m_offsetBeam * g_Engine.v_right + 1280 * m_vecBeam, dont_ignore_monsters, self.edict(), tr);

            @m_pBeam = g_EntityFuncs.CreateBeam("sprites/laserbeam.spr", 80);

            if (m_pBeam !is null)
            {
                m_pBeam.PointEntInit(tr.vecEndPos, self.entindex());
                m_pBeam.SetEndAttachment(1);
                m_pBeam.SetColor(0, 255, 32);
                m_pBeam.SetBrightness(128);
                m_pBeam.SetWidth(32);
                m_pBeam.pev.spawnflags |= SF_BEAM_SPARKSTART;

                CBaseEntity@ pHit = g_EntityFuncs.Instance(tr.pHit);

                if (pHit !is null && pHit.pev.takedamage != DAMAGE_NO)
                {
                    g_WeaponFuncs.ClearMultiDamage();
                    pHit.TraceAttack(self.pev, g_flPitWormBeam, m_vecBeam, tr, 1024);
                    pHit.TakeDamage(self.pev, self.pev, g_flPitWormBeam, 1024);
                }
                else if (tr.flFraction != 1.0)
                {
                    g_Utility.DecalTrace(tr, DECAL_GUNSHOT1 + Math.RandomLong(0, 4));
                    m_pBeam.DoSparks(tr.vecEndPos, tr.vecEndPos);
                }

                m_pBeam.DoSparks(vecEyePos, vecEyePos);

                m_flBeamExpireTime = g_Engine.time + 0.9;

                const float yaw = m_flHeadYaw - m_flBeamDir * 25.0;

                if (-45.0 <= yaw && yaw <= 45.0)
                {
                    m_flHeadYaw = yaw;
                }

                m_flIdealHeadYaw += m_flBeamDir * 50.0;

                g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_WEAPON, g_rgpszShootSounds[Math.RandomLong(0, g_rgpszShootSounds.length() - 1)], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(-5, 5) + 100);
                NetworkMessage m(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
                    m.WriteByte(TE_ELIGHT);
                    m.WriteShort(self.entindex() | (1 << 12));
                    m.WriteCoord(vecEyePos.x);
                    m.WriteCoord(vecEyePos.y);
                    m.WriteCoord(vecEyePos.z);
                    m.WriteCoord(128.0);
                    m.WriteByte(128);
                    m.WriteByte(255);
                    m.WriteByte(128);
                    m.WriteByte(1);
                    m.WriteCoord(2.0);
                m.End();

                @m_pSprite = g_EntityFuncs.CreateSprite("sprites/hlcancer/generic/tele1.spr", vecEyePos, true);

                if (m_pSprite !is null)
                {
                    m_pSprite.SetTransparency(kRenderGlow, 255, 255, 255, 255, kRenderFxNoDissipation);
                    m_pSprite.SetColor(0, 255, 0);
                    m_pSprite.SetAttachment(self.edict(), 1);
                    m_pSprite.SetScale(0.75);
                    m_pSprite.pev.framerate = 10;

                    m_pSprite.TurnOn();
                }
            }
        }
    }
    
    void StrafeBeam() {
        m_offsetBeam += 20 * m_flBeamDir;

        Vector vecEyePos, vecEyeAng;
        CBaseAnimating@ pAnimating = cast<CBaseAnimating@>(self);
        pAnimating.GetAttachment(0, vecEyePos, vecEyeAng);

        m_vecBeam = (m_posBeam - vecEyePos).Normalize();

        m_angleBeam = Math.VecToAngles(m_vecBeam);

        Math.MakeVectors(m_angleBeam);

        m_vecBeam = g_Engine.v_forward;

        m_vecBeam.z = -m_vecBeam.z;

        TraceResult tr;
        g_Utility.TraceLine(vecEyePos, vecEyePos + g_Engine.v_right * m_offsetBeam + m_vecBeam * 1280, dont_ignore_monsters, self.edict(), tr);
        m_pBeam.DoSparks(vecEyePos, vecEyePos);

        m_pBeam.pev.origin = tr.vecEndPos;

        CBaseEntity@ pHit = g_EntityFuncs.Instance(tr.pHit);

        if (pHit !is null && pHit.pev.takedamage != DAMAGE_NO)
        {
            g_WeaponFuncs.ClearMultiDamage();

            pHit.TraceAttack(self.pev, g_flPitWormBeam, m_vecBeam, tr, DMG_ENERGYBEAM);
            pHit.TakeDamage(self.pev, self.pev, g_flPitWormBeam, DMG_ENERGYBEAM);

            //TODO: missing an ApplyMultiDamage call here
            //Should probably replace the TakeDamage call
            //ApplyMultiDamage( pev, pev );
        }
        else if (tr.flFraction != 1.0)
        {
            g_Utility.DecalTrace(tr, DECAL_GUNSHOT1 + Math.RandomLong(0, 4));
            m_pBeam.DoSparks(tr.vecEndPos, tr.vecEndPos);
        }

        NetworkMessage m(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
            m.WriteByte(TE_ELIGHT);
            m.WriteShort(self.entindex() | (1 << 12));
            m.WriteCoord(vecEyePos.x);
            m.WriteCoord(vecEyePos.y);
            m.WriteCoord(vecEyePos.z);
            m.WriteCoord(128);
            m.WriteByte(128);
            m.WriteByte(255);
            m.WriteByte(128);
            m.WriteByte(1);
            m.WriteCoord(2);
        m.End();
    }
    
    void TrackEnemy()
    {
        CBaseEntity@ pEnemy = self.m_hEnemy.GetEntity();

        Vector vecEyePos, vecEyeAng;
        CBaseAnimating@ pAnimating = cast<CBaseAnimating@>(self);
        pAnimating.GetAttachment(0, vecEyePos, vecEyeAng);

        vecEyePos.x = self.pev.origin.x;
        vecEyePos.y = self.pev.origin.y;

        const Vector vecDir = Math.VecToAngles(pEnemy.pev.origin + pEnemy.pev.view_ofs - vecEyePos);

        m_flIdealHeadPitch = Math.min(45, Math.max(-45, Math.AngleDiff(vecDir.x, self.pev.angles.x)));

        const float yaw = Math.AngleDiff(Math.VecToYaw(pEnemy.pev.origin + pEnemy.pev.view_ofs - vecEyePos), self.pev.angles.y);

        if (!m_fLockYaw)
        {
            if (yaw < 0)
            {
                m_flIdealTorsoYaw = Math.max(yaw, m_iLevel == 1 ? -30 : -50);
            }

            if (yaw > 0)
            {
                m_flIdealTorsoYaw = Math.min(yaw, m_iLevel == 2 ? 30 : 50);
            }
        }

        const auto headYaw = Math.max(-45, Math.min(45, m_flTorsoYaw - yaw));

        if (!m_fAttacking || m_pBeam !is null)
            m_flIdealHeadYaw = headYaw;

        if (!m_fLockHeight)
        {
            m_iLevel = 0;

            for (size_t i = m_fTopLevelLocked ? 2 : 3; i > 0; --i)
            {
                if (pEnemy.pev.origin.z > m_flTargetLevels[i])
                {
                    m_iLevel = i;
                    break;
                }
            }

            m_posDesired.z = m_flLevels[m_iLevel];
        }
    }
    
    bool ClawAttack() {
        if (!self.m_hEnemy.IsValid() || self.pev.origin.z != m_posDesired.z || m_flNextMeleeTime > g_Engine.time)
            return false;

        const float distance = (self.pev.origin - self.m_hEnemy.GetEntity().pev.origin).Length2D();

        if (!FVisible(m_posTarget))
        {
            if (distance >= 600.0)
                return false;

            const Vector direction = Math.VecToAngles((m_posTarget - self.pev.origin).Normalize());

            const float yaw = Math.AngleDiff(direction.y, self.pev.angles.y);

            if (m_iLevel == 2)
            {
                if (yaw < 30.0)
                    return false;

                self.pev.sequence = PITWORM_ANIM_Level2AttackLeft;
                m_flIdealHeadYaw = 0;
            }
            else if (m_iLevel == 1)
            {
                if (yaw <= -30.0)
                {
                    self.pev.sequence = PITWORM_ANIM_Level1AttackRight;
                    m_flIdealHeadYaw = 0;
                }
                else if (yaw >= 30.0)
                {
                    self.pev.sequence = PITWORM_ANIM_Level1AttackLeft;
                    m_flIdealHeadYaw = 0;
                }
                else
                {
                    return false;
                }
            }

            g_SoundSystem.EmitSound(self.edict(), CHAN_VOICE, g_rgpszAttackVoiceSounds[Math.RandomLong(0, g_rgpszAttackVoiceSounds.length() - 1)], VOL_NORM, 0.1);

            m_fLockHeight = true;
            m_fLockYaw = true;
            m_fAttacking = true;
            return true;
        }

        m_fLockYaw = false;

        if (m_iLevel == 2)
        {
            const Vector direction = Math.VecToAngles((m_posTarget - self.pev.origin).Normalize());

            const float yaw = Math.AngleDiff(direction.y, self.pev.angles.y);

            if (yaw < 30.0)
            {
                if (distance > 425.0 || yaw <= -50.0)
                {
                    self.pev.sequence = PITWORM_ANIM_RangeAttack;
                    m_posBeam = m_posTarget;
                    m_vecBeam = m_vecTarget;
                    m_angleBeam = Math.VecToAngles(m_vecBeam);
                }
                else
                {
                    self.pev.sequence = PITWORM_ANIM_Level2AttackCenter;
                }
            }
            else
            {
                self.pev.sequence = PITWORM_ANIM_Level2AttackLeft;
                m_flIdealHeadYaw = 0;
                m_fLockYaw = true;
            }
        }
        else if (m_iLevel == 3)
        {
            if (distance <= 425.0)
            {
                self.pev.sequence = PITWORM_ANIM_Level3Attack1 + Math.RandomLong(0, 1);
            }
            else
            {
                self.pev.sequence = PITWORM_ANIM_RangeAttack;
                m_posBeam = m_posTarget;
                m_vecBeam = m_vecTarget;
                m_angleBeam = Math.VecToAngles(m_vecBeam);
            }
        }
        else
        {
            if (m_iLevel != 1)
                return false;

            const Vector direction = Math.VecToAngles((m_posTarget - self.pev.origin).Normalize());

            const float yaw = Math.AngleDiff(direction.y, self.pev.angles.y);

            if (yaw < 50.0)
            {
                if (yaw > -30.0)
                {
                    if (distance > 425.0)
                    {
                        self.pev.sequence = PITWORM_ANIM_RangeAttack;
                        m_posBeam = m_posTarget;
                        m_vecBeam = m_vecTarget;
                        m_angleBeam = Math.VecToAngles(m_vecBeam);
                    }
                    else
                    {
                        self.pev.sequence = PITWORM_ANIM_Level1AttackCenter;
                    }
                }
                else
                {
                    self.pev.sequence = PITWORM_ANIM_Level1AttackRight;
                }
            }
            else
            {
                self.pev.sequence = PITWORM_ANIM_Level1AttackLeft;
                m_flIdealHeadYaw = 0;
                m_fLockYaw = true;
            }
        }

        if (self.pev.sequence == PITWORM_ANIM_RangeAttack)
        {
            g_SoundSystem.EmitSound(self.edict(), CHAN_VOICE, "hlcancer/op4/pitworm/pit_worm_attack_eyeblast.wav", VOL_NORM, 0.1);
        }
        else
        {
            g_SoundSystem.EmitSound(self.edict(), CHAN_VOICE, g_rgpszAttackVoiceSounds[Math.RandomLong(0, g_rgpszAttackVoiceSounds.length() - 1)], VOL_NORM, 0.1);
        }

        m_fAttacking = true;
        m_fLockHeight = true;

        return true;
    }
    
    //Ugly shitcode. Don't ever use this ~ xWhitey
    /*CBaseEntity@ FindBestVisiblePlayer() {
        array<float> aflDistances;
        aflDistances.resize(0);
        aflDistances.resize(33);
        for (int idx = 1; idx <= g_Engine.maxClients; idx++) {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(idx);
            if (pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive()) {
                aflDistances[idx] = -99999.f;
                continue;
            }
            if (!FVisible(pPlayer.pev.origin)) {
                aflDistances[idx] = -99999.f;
                continue;
            }
            aflDistances[idx] = ((pPlayer.pev.origin - self.pev.origin).Length());
        }
        float flSmallest = aflDistances[1];
        uint uiSmallestIdx = 1;
        for (uint idx = 2; idx < 33; idx++) {
            if (aflDistances[idx] == -99999.f) continue;
            if (flSmallest < aflDistances[idx]) {
                flSmallest = aflDistances[idx];
                uiSmallestIdx = idx;
            }
        }
        CBasePlayer@ pResult = g_PlayerFuncs.FindPlayerByIndex(uiSmallestIdx);
        
        return @pResult;
    }*/
    
    int Classify() {
        return CLASS_XRACE_SHOCK;
    }
    
    CBaseEntity@ FindClosestEnemy(float _Radius) {
        CBaseEntity@ pEntity = null;
        CBaseEntity@ pEnemy = null;
        float flNearest = _Radius;

        do {
            @pEntity = g_EntityFuncs.FindEntityInSphere(pEntity, self.pev.origin, _Radius, "*", "classname" ); 
        
            if (pEntity is null || !pEntity.IsAlive())
                continue;

            if (pEntity.pev.classname == "squadmaker")
                continue;

            if (pEntity.entindex() == self.entindex())
                continue;
                
            if (!FVisible(pEntity, false))
                continue;
            
            /*if (pEntity.edict() is self.pev.owner) //No.
                continue;*/
            
            int rel = self.IRelationship(pEntity);
            if (rel == R_AL || rel == R_NO)
                continue;

            float flDistance = (pEntity.pev.origin - self.pev.origin).Length();
            if (flDistance < flNearest) {
                flNearest = flDistance;
                @pEnemy = pEntity;
            }
        } while (pEntity !is null);

        return pEnemy;
    }
    
    void NextActivity()
    {
        Math.MakeAimVectors(self.pev.angles);

        //TODO: never used?
        const Vector moveDistance = m_posDesired - self.pev.origin;
        
        CBaseMonster@ pSelfMonster = cast<CBaseMonster@>(self);

        if (pSelfMonster.m_hEnemy.IsValid())
        {
            if (!pSelfMonster.m_hEnemy.GetEntity().IsAlive())
            {
                pSelfMonster.m_hEnemy = null;
                m_flIdealHeadYaw = 0;
            }
            if (!FVisible(pSelfMonster.m_hEnemy.GetEntity().pev.origin)) {
                pSelfMonster.m_hEnemy = null;
                m_flIdealHeadYaw = 0;
                m_posDesired.z = m_flLevels[2];
                m_fTopLevelLocked = true;
            }
        }

        if (g_Engine.time > m_flLastSeen + 15.0)
        {
            if (pSelfMonster.m_hEnemy.IsValid())
            {
                if ((self.pev.origin - pSelfMonster.m_hEnemy.GetEntity().pev.origin).Length2D() > 700.0)
                    pSelfMonster.m_hEnemy = null;
            }
        }

        if (!pSelfMonster.m_hEnemy.IsValid())
        {
            self.Look(4096);
            CBaseEntity@ pEntity = FindClosestEnemy(4096.f);
            pSelfMonster.m_hEnemy = EHandle(pEntity);

            if (pSelfMonster.m_hEnemy.IsValid())
            {
                //g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[DEBUG] Enemy sighted! Distance: " + string((self.pev.origin - pEntity.pev.origin).Length()) + "\n");
                m_fTopLevelLocked = false;
                g_SoundSystem.EmitSound(self.edict(), CHAN_VOICE, "hlcancer/op4/pitworm/pit_worm_alert.wav", VOL_NORM, 0.1);
            }
        }

        if (!pSelfMonster.m_hEnemy.IsValid() || m_fFirstSighting)
        {
            if (m_iWasHit == 1)
            {
                self.pev.sequence = PITWORM_ANIM_Flinch1 + Math.RandomLong(0, 1);
                m_iWasHit = 0;

                PainSound();

                m_fLockHeight = false;
                m_fLockYaw = false;
                m_fAttacking = false;
            }
            else if (self.pev.origin.z == m_posDesired.z)
            {
                if (abs(int(m_flIdealTorsoYaw - m_flTorsoYaw)) > 10 || !ClawAttack())
                {
                    if (Math.RandomLong(0, 2) == 0)
                        IdleSound();

                    self.pev.sequence = PITWORM_ANIM_IdleShort;

                    m_fLockHeight = false;
                    m_fLockYaw = false;
                    m_fAttacking = false;
                }
            }
            else
            {
                if (Math.RandomLong(0, 2) == 0)
                    IdleSound();

                self.pev.sequence = PITWORM_ANIM_IdleLong;

                m_fLockHeight = false;
                m_fLockYaw = false;
                m_fAttacking = false;
            }
        }
        else
        {
            self.pev.sequence = PITWORM_ANIM_Scream;
            m_fFirstSighting = true;
        }
    }
    
    void TraceAttack(entvars_t@ pevAttacker, float flDamage, const Vector& in vecDir, TraceResult& in traceResult, int bitsDamageType)
    {
        if (m_bDeadFlag) return;
    
        if (traceResult.iHitgroup == 1)
        {
            if (g_Engine.time > m_flTakeHitTime)
            {
                self.pev.health -= flDamage;

                if (self.pev.health <= 0)
                {
                    self.pev.health = self.pev.max_health;
                    m_iWasHit = 1;
                    m_flTakeHitTime = Math.RandomLong(2, 4) + g_Engine.time;
                }

                if (self.m_bloodColor != DONT_BLEED)
                {
                    //self.SpawnBlood(traceResult.vecEndPos - vecDir * 4, m_bloodColor, flDamage * 10.0);
                    self.TraceBleed(flDamage, vecDir, traceResult, bitsDamageType);

                    CBaseMonster@ pSelfMonster = cast<CBaseMonster@>(self);

                    if (pevAttacker !is null && !pSelfMonster.m_hEnemy.IsValid())
                    {
                        CBaseEntity@ pAttacker = g_EntityFuncs.Instance(pevAttacker);

                        if (pAttacker !is null && pAttacker.MyMonsterPointer() !is null)
                        {
                            pSelfMonster.m_hEnemy = EHandle(pAttacker);
                            g_SoundSystem.EmitSound(self.edict(), CHAN_VOICE, "hlcancer/op4/pitworm/pit_worm_alert.wav", VOL_NORM, 0.1);

                            if (!m_fFirstSighting)
                            {
                                self.pev.sequence = PITWORM_ANIM_Scream;
                                m_fFirstSighting = true;
                                return;
                            }
                        }
                    }
                }

                if (0 == self.pev.skin)
                {
                    self.pev.skin = 1;
                    m_flLastBlinkInterval = g_Engine.time;
                    m_flLastBlinkTime = g_Engine.time;
                }
            }
        }
        else if (self.pev.dmgtime != g_Engine.time || Math.RandomLong(0, 10) <= 0)
        {
            g_Utility.Ricochet(traceResult.vecEndPos, Math.RandomFloat(1, 2));
            self.pev.dmgtime = g_Engine.time;
        }
    }
    
    void HandleAnimEvent(MonsterEvent@ pEvent) {
        switch (pEvent.event)
        {
        case 1: // PITWORM_UP_AE_HITGROUND
            g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_WEAPON, g_rgpszHitGroundSounds[Math.RandomLong(0, g_rgpszHitGroundSounds.length() - 1)], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(-5, 5) + 100);
            
            if (self.pev.sequence == PITWORM_ANIM_Level2AttackCenter)
                g_PlayerFuncs.ScreenShake(self.pev.origin, 12.0, 100.0, 2.0, 1000.0);
            else
                g_PlayerFuncs.ScreenShake(self.pev.origin, 4.0, 3.0, 1.0, 750.0);
                
            break;

        case 2: // PITWORM_UP_AE_SHOOTBEAM
            if (g_Engine.time - m_flLastEventTime >= 1.1)
            {
                CBaseMonster@ pSelfMonster = cast<CBaseMonster@>(self);
                if (!pSelfMonster.m_hEnemy.IsValid()) break;
                CBaseEntity@ pEnemy = pSelfMonster.m_hEnemy.GetEntity();
                m_posBeam = pEnemy.pev.origin;
                if (pEnemy.IsPlayer() && (pEnemy.pev.flags & FL_DUCKING) == 0) {
                    m_posBeam.z += 24.0;
                }

                Vector vecEyePos, vecEyeAng;
                CBaseAnimating@ pAnimating = cast<CBaseAnimating@>(self);
                pAnimating.GetAttachment(0, vecEyePos, vecEyeAng);

                m_vecBeam = (m_posBeam - vecEyePos).Normalize();

                m_angleBeam = Math.VecToAngles(m_vecBeam);

                ShootBeam();

                m_fLockYaw = true;
            }
            break;

        case 4: // PITWORM_UP_AE_LOCKYAW
            m_fLockYaw = true;
            break;

        default:
            break;
        }
    }

    float m_flNextPainSound;

    Vector m_vecTarget;
    Vector m_posTarget;
    Vector m_vecDesired;
    Vector m_posDesired;

    float m_offsetBeam;
    Vector m_posBeam;
    Vector m_vecBeam;
    Vector m_angleBeam;

    float m_flBeamExpireTime;
    float m_flBeamDir;

    float m_flTorsoYaw;
    float m_flHeadYaw;
    float m_flHeadPitch;
    float m_flIdealTorsoYaw;
    float m_flIdealHeadYaw;
    float m_flIdealHeadPitch;

    array<float> m_flLevels;
    array<float> m_flTargetLevels;

    float m_flLastSeen;
    float m_flPrevSeen;

    int m_iLevel;
    float m_flLevelSpeed;

    CBeam@ m_pBeam;
    CSprite@ m_pSprite;

    bool m_fAttacking;
    bool m_fLockHeight;
    bool m_fLockYaw;

    int m_iWasHit;
    float m_flTakeHitTime;
    float m_flHitTime;

    float m_flNextMeleeTime;
    float m_flNextRangeTime;
    float m_flDeathStartTime;

    bool m_fFirstSighting;
    bool m_fTopLevelLocked;

    float m_flLastBlinkTime;
    float m_flLastBlinkInterval;
    float m_flLastEventTime;
    
    //bugfixes
    bool m_bDeadFlag;
}

class COFPitWormSteamTrigger : ScriptBaseEntity /* there should be CPointEntity, but it's useless in Sven */ {
    void Spawn() {
        self.pev.solid = SOLID_NOT;
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.effects = EF_NODRAW;
        g_EntityFuncs.SetOrigin(self, self.pev.origin);
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value) {
        COFPitWormUp@ pPitworm = cast<COFPitWormUp@>(CastToScriptClass(g_EntityFuncs.FindEntityByClassname(null, "monster_pitworm_up")));

        if (pPitworm !is null) {
            if (pPitworm.m_iLevel == 3 && !pPitworm.m_bDeadFlag) {
                pPitworm.pev.health = pPitworm.pev.max_health;

                pPitworm.m_iWasHit = 1;
                pPitworm.m_iLevel = 2;

                pPitworm.m_flTakeHitTime = Math.RandomLong(2, 4) + g_Engine.time;

                pPitworm.m_posDesired.z = pPitworm.m_flLevels[2];
            }

            pPitworm.m_fTopLevelLocked = true;
        }
    }
};