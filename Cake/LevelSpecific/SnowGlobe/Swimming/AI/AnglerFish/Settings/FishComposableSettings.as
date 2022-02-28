enum EFishEffectsMode
{
	None,
	Idle,
	Searching,
	Attack
}

struct FFishEffectsFactors
{
	UPROPERTY()
	float Idle = 1.f;

	UPROPERTY()
	float Searching = 1.f;

	UPROPERTY()
	float Attacking = 1.f;

	FFishEffectsFactors(float IdleFactor, float SearchingFactor, float AttackingFactor)
	{
		Idle = IdleFactor;
		Searching = SearchingFactor;
		Attacking = AttackingFactor;
	}

	float GetFactor(EFishEffectsMode Mode)
	{
		switch (Mode)
		{
			case EFishEffectsMode::Searching:
				return Searching;
			case EFishEffectsMode::Attack:
				return Attacking;
		}
		return Idle;
	}
}

UCLASS(Meta = (ComposeSettingsOnto = "UFishComposableSettings"))
class UFishComposableSettings : UHazeComposableSettings
{
    // How long we take to complete a turn towards wanted destination
    UPROPERTY(Category = "FishBehaviour|Idle")
    float IdleTurnDuration = 20.f;

	// Default acceleration when not in combat
    UPROPERTY(Category = "FishBehaviour|Idle")
	float IdleAcceleration = 2000.f;

	// When investigating a scene point we move to a point offset by this from the actual scene point
    UPROPERTY(Category = "FishBehaviour|Investigating")
	FVector InvestigationOffset = FVector(0.f, 0.f, 1000.f);

    // How long we take to complete a turn towards wanted destination
    UPROPERTY(Category = "FishBehaviour|Investigating")
    float InvestigationTurnDuration = 8.f;

	// Default acceleration when investigating
    UPROPERTY(Category = "FishBehaviour|Investigating")
	float InvestigationAcceleration = 2000.f;

	// For how long we remain looking at investigation point when close
    UPROPERTY(Category = "FishBehaviour|Investigating")
	float InvestigationDuration = 5.f;

	// Default acceleration when maneuvering to attack position
    UPROPERTY(Category = "FishBehaviour|Combat")
	float PursueAcceleration = 2500.f;

    // Acceleration when performing attacks
    UPROPERTY(Category = "FishBehaviour|Attack")
    float AttackRunAcceleration = 8000.f;

    // Acceleration when maw camera has been activated
    UPROPERTY(Category = "FishBehaviour|Attack")
    float AttackMawCameraAcceleration = 4000.f;

    // If false we always try to start attack in front of player camera. If true, we use nearest convenient location.
    UPROPERTY(Category = "FishBehaviour|Combat")
    bool bAllowBackStabbing = false;

	// For how long will we try to squeeze past obstacles when engaging before we just attack anyway
    UPROPERTY(Category = "FishBehaviour|Combat")
	float PursueFrustrationDuration = 3.f;

    // How long we take to complete a turn towards wanted destination
    UPROPERTY(Category = "FishBehaviour|Idle")
    float PursueTurnDuration = 8.f;

    // How long Fish will pause to recover after an attack completes before coming around for another try.
    UPROPERTY(Category = "FishBehaviour|Recovery")
    float RecoverDuration = 3.f;

    // Acceleration when recovering after attack
    UPROPERTY(Category = "FishBehaviour|Recovery")
    float RecoverAcceleration = 2000.f;

    // How long we take to complete a turn towards wanted destination
    UPROPERTY(Category = "FishBehaviour|Recovery")
    float RecoverTurnDuration = 5.f;

    // When pursuing, we launch an attack run if target is this close to forward direction (degrees)    
	UPROPERTY(Category = "FishBehaviour|Attack")
    float LaunchAttackAngle = 90.0f;

    // When pursuing, we launch an attack if we're closer than this to target
	UPROPERTY(Category = "FishBehaviour|Attack")
    float LaunchAttackRange = 1500.0f;

    // How long we take to complete a turn towards wanted destination
    UPROPERTY(Category = "FishBehaviour|Attack")
    float AttackTurnDuration = 0.5f;

    // How many seconds after beginning an attack run that Fish will try to track target
    UPROPERTY(Category = "FishBehaviour|Attack")
    float AttackRunTrackDuration = -1.0f;

    // If true, attack runs will use target current velocity to calculate attack destination
    UPROPERTY(Category = "FishBehaviour|Attack")
    bool bAttackRunPrediction = true;

    // Attack run can hit a target within this distance of it's center path
    UPROPERTY(Category = "FishBehaviour|Attack")
    float AttackRunHitRadius = 1800.f;

    // Attack run check this many seconds ahead if it will hit
    UPROPERTY(Category = "FishBehaviour|Attack")
    float AttackRunHitDuration = 0.0f;

	// How fast do we accelerate when fleeing from players
    UPROPERTY(Category = "FishBehaviour|Flee")
    float FleeAcceleration = 1500.f;

    // How long we take to complete a turn towards wanted destination
    UPROPERTY(Category = "FishBehaviour|Flee")
    float FleeTurnDuration = 5.f;

    // At what angle fish can pitch when climbing towards the surface
    UPROPERTY(Category = "FishBehaviour|Idle")
    float MaxSwimPitchUp = 50.f;

    // At what angle fish can pitch when diving downwards
    UPROPERTY(Category = "FishBehaviour|Idle")
    float MaxSwimPitchDown = 30.f;

    // Fraction of normal width vision cone tightens to when chasing a target
    UPROPERTY(Category = "FishBehaviour|Perception")
    float VisionConeChaseFraction = 0.8f;

	// If > 0, players can hide by moving outside the vision cone/sphere for this many seconds when fish is preparing to lunge
	UPROPERTY(Category = "FishBehaviour|Perception")
	float PrepareLungeKeepTargetInViewTime = 0.5f;

    // How fast we accelerate when preparing to lunge
    UPROPERTY(Category = "FishBehaviour|Attack")
    float PrepareLungeAcceleration = 1000.f;

	// How many seconds we give target to flee after being spotted until we lunge
    UPROPERTY(Category = "FishBehaviour|Combat")
	float PrepareLungeDuration = 8.f;

	// How fast we turn towards target when preparing to lunge
    UPROPERTY(Category = "FishBehaviour|Combat")
	float PrepareLungeTurnDuration = 0.4f;

    // How fast we accelerate when lunging
    UPROPERTY(Category = "FishBehaviour|Attack")
    float AttackLungeAcceleration = 150000.f;

    UPROPERTY(Category = "FishBehaviour|Combat")
	float PrepareBlindChargeDuration = 1.f;

	// How fast we accelerate towards target when preparing a blind charge
    UPROPERTY(Category = "FishBehaviour|Combat")
    float PrepareBlindChargeAcceleration = 1000.f;

	// How fast we turn towards target when preparing a blind charge
    UPROPERTY(Category = "FishBehaviour|Combat")
	float PrepareBlindChargeTurnDuration = 0.8f;

	// How fast we accelerate towards target during a blind charge
    UPROPERTY(Category = "FishBehaviour|Attack")
    float AttackBlindChargeAcceleration = 10000.f;

	// How fast we turn towards target during a blind charge
    UPROPERTY(Category = "FishBehaviour|Attack")
    float AttackBlindChargeTurnDuration = 1.f;

	// We always abort blind charge after this many seconds
    UPROPERTY(Category = "FishBehaviour|Attack")
    float AttackBlindChargeMaxDuration = 4.f;

	// How hard players will be pushed away when near fish
    UPROPERTY(Category = "Fish|Push")
    float PushForce = 1500.f;

	// For how many seconds players will tumble when pushed by fish
    UPROPERTY(Category = "Fish|Push")
    float PushDuration = 1.f;

	// Effects color used when idle (roaming about)
	UPROPERTY(Category = "Effects")
	FLinearColor IdleColor = FLinearColor(R=0.54,G=0.46,B=0.0,A=1.f);

	// Effects color used when searching (attracted by noise)
	UPROPERTY(Category = "Effects")
	FLinearColor SearchingColor = FLinearColor(R=1,G=0.15,B=0.0,A=1.3f);

	// Effects color used when attacking (food has been spotted)
	UPROPERTY(Category = "Effects")
	FLinearColor AttackColor = FLinearColor(R=1.0,G=0.0,B=0.0,A=1.5f);

	// Effects blend duration when changing effects mode to idle
	UPROPERTY(Category = "Effects")
	float ToIdleBlendDuration = 10.f;

	// Effects blend duration when changing effects mode to searching
	UPROPERTY(Category = "Effects")
	float ToSearchingBlendDuration = 5.f;

	// Effects blend duration when changing effects mode to attack
	UPROPERTY(Category = "Effects")
	float ToAttackBlendDuration = 2.f;

	// Lantern point light color is multiplied by this when idle/searching/attacking
	UPROPERTY(Category = "Effects")
	FFishEffectsFactors PointLightColorFactor = FFishEffectsFactors(1.f, 1.f, 1.f);

	// Intensity of lantern point light
	UPROPERTY(Category = "Effects")
	float PointLightIntensity = 10.f;

	// Light cone color multiplier when idle/searching/attacking
	UPROPERTY(Category = "Effects")
	FFishEffectsFactors LightConeColorFactor = FFishEffectsFactors(1.f, 1.f, 5.f);

	// Mesh emissive color multiplier when idle/searching/attacking
	UPROPERTY(Category = "Effects")
	FFishEffectsFactors MeshEmissiveColorFactor = FFishEffectsFactors(5.f, 10.f, 50.f);

	// Lantern haze sphere color is multiplied by this when idle/searching/attacking
	UPROPERTY(Category = "Effects")
	FFishEffectsFactors HazeSphereColorFactor = FFishEffectsFactors(1.f, 1.f, 3.5f);

	// Lantern haze sphere opacity
	UPROPERTY(Category = "Effects")
	float HazeSphereOpacity = 0.8f;

	// Lantern haze sphere softness
	UPROPERTY(Category = "Effects")
	float HazeSphereSoftness = 2.f;

	// Lantern spot light color is multiplied by this when idle/searching/attacking
	UPROPERTY(Category = "Effects")
	FFishEffectsFactors SpotLightColorFactor = FFishEffectsFactors(1.f, 1.f, 1.f);

	// Lantern god ray color is multiplied by this when idle/searching/attacking
	UPROPERTY(Category = "Effects")
	FFishEffectsFactors GodrayColorFactor = FFishEffectsFactors(1.f, 1.f, 1.f);
}
