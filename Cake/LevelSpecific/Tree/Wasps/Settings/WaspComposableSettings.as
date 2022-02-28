// Wasps have several behaviour states each in which one or more behaviour capabilities are possible
enum EWaspState
{
    None,
    Idle,
    Combat,
    Telegraphing,
    Attack,
    Grapple,
    Recover,
    Stunned,
	Flee,

	MAX
}

enum EWaspTargetSelection
{
	LeastAttackersClosest,	// Try to attack the available target with least number of attackers which is closest
	Alternate,				// Try to alternate between available targets
}

struct FWaspAggressionThreshold
{
	// When this health fraction has been reached we will apply the settings. E.g. if 0.7 we will apply the settings when we fall below 70% health.
	UPROPERTY()
	float HealthFraction = 0.f;

	// These settings will be applied when threshold health fraction has been reached
	UPROPERTY()
	UWaspComposableSettings Settings;

	// This capability sheet will be added when threshold health fraction has been reached. Any previous sheet will be removed.
	UPROPERTY()
	UHazeCapabilitySheet CapabilitySheet;
}

UCLASS(Meta = (ComposeSettingsOnto = "UWaspComposableSettings"))
class UWaspComposableSettings : UHazeComposableSettings
{
	// Acceleration duration of rotation when flying
    UPROPERTY(Category = "WaspBehaviour|Idle")
	float FlyingRotationDuration = 1.5f;

	// Default acceleration when not in combat (e.g. following spline or moving to scene point)
    UPROPERTY(Category = "WaspBehaviour|Idle")
	float IdleAcceleration = 1000.f;

	// If true we will rotate to look at best potential target when following spline
    UPROPERTY(Category = "WaspBehaviour|Idle")
	bool bTrackTargetWhenFollowingSpline = false;

    // Maximum distance at which a target is considered suitable to attack
    UPROPERTY(Category = "WaspBehaviour|Targeting")
    float MaxTargetDistance = 2000.f;

    // Number of attack we try to perform before considering switching target (as long as target is valid)
    UPROPERTY(Category = "WaspBehaviour|Targeting")
    uint8 NumAttacksBeforeSwitchingTarget = 0;

    // How we choose which target to attack 
    UPROPERTY(Category = "WaspBehaviour|Targeting")
    EWaspTargetSelection TargetSelection;

    // If false we always try to start attack in front of player camera. If true, we use nearest convenient location.
    UPROPERTY(Category = "WaspBehaviour|Combat")
    bool bAllowBackStabbing = false;

	// Default acceleration when maneuvering to attack position
    UPROPERTY(Category = "WaspBehaviour|Combat")
	float EngageAcceleration = 2500.f;

    // How high above the target will we try to engage from?
    UPROPERTY(Category = "WaspBehaviour|Combat")
    float EngageHeight = 300.f;

    // How far away from target do we need to at least be to engage?
    UPROPERTY(Category = "WaspBehaviour|Combat")
    float EngageMinDistance = 500.f;

    // How far away from target can we be at most when engaging?
    UPROPERTY(Category = "WaspBehaviour|Combat")
    float EngageMaxDistance = 800.f;

	// For how long will we try to squeeze past obstacles when engaging before we just attack anyway
    UPROPERTY(Category = "WaspBehaviour|Combat")
	float EngageFrustrationDuration = 3.f;

    // When performing combat positioning circle hops, how long time will we spend in each hop
    UPROPERTY(Category = "WaspBehaviour|Combat")
    float CircleHopDuration = 3.f;

    // When becoming aware of a threat (such as being peppered by sap), how long does it take to react to it?
    UPROPERTY(Category = "WaspBehaviour|ThreatResponse")
    float ThreatReactionTime = 0.5f;

    // Maximum range for considering threats
	UPROPERTY(Category = "WaspBehaviour|ThreatResponse")
    float MaxThreatRange = 2000.f;

    // If true, we only attack target when no one else is currently doing so. If false, then all is permitted in love and war!
    UPROPERTY(Category = "WaspBehaviour|GentlemanFighting")
    bool bUseGentleManFighting = true;

    // How far away from target we try to be when gentleman behaviour keeps us from engaging target
    UPROPERTY(Category = "WaspBehaviour|GentlemanFighting")
    float GentlemanDistance = 1200.f;

    // How high above target we try to be when gentleman behaviour keeps us from engaging target
    UPROPERTY(Category = "WaspBehaviour|GentlemanFighting")
    float GentlemanHeight = 800.f;

    UPROPERTY(Category = "WaspBehaviour|GentlemanFighting")
    int GentlemanMaxAttackersCody = 1;

    UPROPERTY(Category = "WaspBehaviour|GentlemanFighting")
    int GentlemanMaxAttackersMay = 2;

    // How long wasp will pause to recover after an attack completes before coming around for another try
    UPROPERTY(Category = "WaspBehaviour|Recovery")
    float RecoverDuration = 5.f;

    // How long wasp will pause to recover after being stunned
    UPROPERTY(Category = "WaspBehaviour|Recovery")
    float PostStunRecoverDuration = 5.f;

    // How far upwards wasp will try to rise when recovering
    UPROPERTY(Category = "WaspBehaviour|Recovery")
    float RecoverHeight = 400.f;

    // How hard we accelerate during recovery, when applicable
    UPROPERTY(Category = "WaspBehaviour|Recovery")
    float RecoverAcceleration = 10.f;

    // Is true, we will be playing the exhausted animnation for this duration past normal recovery time
    UPROPERTY(Category = "WaspBehaviour|Recovery")
    float ExhaustedTime = 0.f;

    // How long wasp will pause after being sapped before shaking it off
    UPROPERTY(Category = "WaspBehaviour|Stunned")
    float StunnedDuration = 2.f;

	// Max Time wasp will shake of before finished
	UPROPERTY(Category = "WaspBehaviour|Stunned")
	float StunnedMaxDuration = 5.f;

	// How fast we fall during stun
	UPROPERTY(Category = "WaspBehaviour|Stunned")
	float StunAcceleration = 2000.f;

    // With more saps than this, it will use max amount of time to get rid of saps. 
    UPROPERTY(Category = "WaspBehaviour|Stunned")
    float SapRemovalThreshold = 10.f;

	//Amount to stun wasp
	UPROPERTY(Category = "WaspBehaviour|Stunned")
	float SapAmountToStun = 2.f;

	// How far wasp will fall when stunned by sap
	UPROPERTY(Category = "WaspBehaviour|Stunned")
	float StunnedFallHeight = 200.f;

	// How long we wait after accumulating enough sap until we count as stunned
	UPROPERTY(Category = "WaspBehaviour|Stunned")
	float StunDelay = 0.f;

    // How long wasp will pause after gaining a suitable position to attack before commencing attack
    UPROPERTY(Category = "WaspBehaviour|Telegraphing")
    float PrepareAttackDuration = 2.f;

    // How long before we start attack should we start taunt?
    UPROPERTY(Category = "WaspBehaviour|Telegraphing")
    float TauntDuration = 2.f;

    UPROPERTY(Category = "WaspBehaviour|Telegraphing")
    float TauntHackTimeScaling = 1.f;

	// If true, we will follow up regular taunt with a taunt where we expose ourselves to attack
    UPROPERTY(Category = "WaspBehaviour|Telegraphing")
    bool bExposedTauntAfterRegular = false;

    // How many seconds after beginning an attack run that wasp will try to track target
    UPROPERTY(Category = "WaspBehaviour|Attack")
    float AttackRunTrackDuration = 1.0f;

	// Damage from attack run
	UPROPERTY(Category = "WaspBehaviour|Attack")
    float AttackRunDamage = 0.5f;

	// Max velocity from attack run knockbacks
	UPROPERTY(Category = "WaspBehaviour|Attack")
    float KnockBackForce = 1000.f;

    // Acceleration when performing attacks
    UPROPERTY(Category = "WaspBehaviour|Attack")
    float AttackRunAcceleration = 5000.f;

    // If true, attack runs will use target current velocity to calculate attack destination
    UPROPERTY(Category = "WaspBehaviour|Attack")
    bool bAttackRunPrediction = true;

    // Attack run can hit a target within this distance of it's center path
    UPROPERTY(Category = "WaspBehaviour|Attack")
    float AttackRunHitRadius = 100.f;

    // Attack run check this many seconds ahead if it will hit
    UPROPERTY(Category = "WaspBehaviour|Attack")
    float AttackRunHitDuration = 0.1f;

    // Can we abort an attack run by hitting wasp with sap?
    UPROPERTY(Category = "WaspBehaviour|Attack")
    bool bCanStunDuringAttackRun = false;

    // If we have entries here, we will apply the settings in that entry when we reach that fraction of health.
    UPROPERTY(Category = "WaspBehaviour|AggressionThresholds")
    TArray<FWaspAggressionThreshold> AggressionThresholds;

	// If > 1 we will attack the same target this many times in a row without pausing to telegraph in between and using a custom recovery time
    UPROPERTY(Category = "WaspBehaviour|QuickAttack")
	uint8 NumQuickAttacks = 0;

	// Recovery time when performing a quick attack
    UPROPERTY(Category = "WaspBehaviour|QuickAttack")
	float QuickAttackRecoveryDuration = 0.75f;

	// Recovery time when performing a quick attack if last attack run hit a player
    UPROPERTY(Category = "WaspBehaviour|QuickAttack")
	float QuickAttackHitRecoveryDuration = 1.75f;

    // If 0 we only shoot single shots. Otherwise shoot salvos every n'th times, i.e. 1 -> every time, 2 -> every other time etc
    UPROPERTY(Category = "WaspBehaviour|Shooting")
    uint8 SalvoFrequency = 0;

    // We shoot this many shots in each salvo
    UPROPERTY(Category = "WaspBehaviour|Shooting")
    uint8 NumShotsInSalvo = 3;

    // How many seconds in between each salvo shot
    UPROPERTY(Category = "WaspBehaviour|Shooting")
    float SalvoShotInterval = 0.8f;

    // How fast do we launch shots
    UPROPERTY(Category = "WaspBehaviour|Shooting")
    float ProjectileLaunchSpeed = 1500.f;

    // How often (0..1) will we use a high parabola when shooting instead of a low?
    UPROPERTY(Category = "WaspBehaviour|Shooting")
    float HighParabolaFraction = 0.f;

	// Any projectiles will explode/disable themselves this many seconds after being launched
    UPROPERTY(Category = "WaspBehaviour|Shooting")
	float ProjectileLifeTime = 3.f;

    // How often wasp is allowed to grapple in seconds, counted from the time a grapple was last completed by any wasp.
    UPROPERTY(Category = "WaspBehaviour|Grappling")
    float GrappleCooldown = 60.f;

	// How fast do we accelerate when fleeing from players
    UPROPERTY(Category = "WaspBehaviour|Flee")
    float FleeAcceleration = 3000.f;

	// Width of attack run decal
    UPROPERTY(Category = "Effects")
    float AttackRunDecalWidth = 5.f;

	// We die when we've suffered this many sap explosions
	UPROPERTY(Category = "Health")
	int HitPoints = 1;

	// After each sap explosion we are invulnerable for this number of seconds
	UPROPERTY(Category = "Health")
	float TakeDamageCooldown = 3.f; 

	// If true we face next (probable) target during hurt reaction
	UPROPERTY(Category = "Health")
	bool bFaceTargetWhenHurt = false; 

	// We'll enter this state when recovering from taking damage
	UPROPERTY(Category = "Health")
	EWaspState PostDamageState = EWaspState::Idle;

	// How near does exploding sap have to be to kill wasp?
	UPROPERTY(Category = "Health")
	float ExplodingSapDeathRadius = 300.f;

	// How near does a match need to hit to explode attached sap?
	UPROPERTY(Category = "Health")
	float IgniteAttachedSapRadius = 100.f;

	// Component to which the health bar is attached
	UPROPERTY(Category = "GUI")
	FName HealthBarAttachComponent = n"CharacterMesh0";

	// Socket to which health bar is attached
	UPROPERTY(Category = "GUI")
	FName HealthBarAttachSocket = n"Head";

	// Offset of health bar
	UPROPERTY(Category = "GUI")
	FVector HealthBarOffset = FVector(0.f, 0.f, 200.f);

	// Component to which enemy indicator is attached
	UPROPERTY(Category = "GUI")
	FName EnemyIndicatorAttachComponent = n"CharacterMesh0";

	// Socket to which enemy indicator is attached
	UPROPERTY(Category = "GUI")
	FName EnemyIndicatorAttachSocket = n"Head";

	// Offset of enemy indicator widget
	UPROPERTY(Category = "GUI")
	FVector EnemyIndicatorGUIOffset = FVector(0.f, 0.f, 200.f);

	// Enemy indicator will only be initially shown when wasp is within this range.
	UPROPERTY(Category = "GUI")
	float EnemyIndicatorShowRange = 10000.f;

	// Enemy indicator will be hidden when wasp is outside this range.
	UPROPERTY(Category = "GUI")
	float EnemyIndicatorHideRange = 15000.f;

	// Minimum opacity of enemy indicators. If 0, they will only be shown when an attack is under way.
	UPROPERTY(Category = "GUI")
	float EnemyIndicatorMinOpacity = 0.0f;

	// If true we will flash enemy indicator during attack telegraph as well as during attack itself
	UPROPERTY(Category = "GUI")
	bool bEnemyIndicatorHighlightWhenTelegraphing = false;
}
