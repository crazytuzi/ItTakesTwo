
import Cake.LevelSpecific.Tree.Swarm.Animation.SwarmSkeletalMeshComponent;
import Cake.LevelSpecific.Tree.Swarm.Animation.SwarmAnimationSettingsDataAsset;
import Vino.Movement.MovementSettings;

enum ESwarmShape 
{
	None,
	Hammer,
	Slide,
	Shield,
	RightHand,
	Tornado,
	Sword,
	RailSword,
	HandGrab,
	Airplane,
	MAX,
}

UCLASS(Meta = (ComposeSettingsOnto = "USwarmBehaviourSettings"))
class USwarmBehaviourSettings : USwarmBehaviourBaseSettings
{
 	UPROPERTY(meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsHammer Hammer;

	UPROPERTY(meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsHitAndRun HitAndRun;

	UPROPERTY(meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsSlide Slide;

	UPROPERTY(meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsSoloShield SoloShield;

	UPROPERTY(meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsSoloHandSmash SoloHandSmash;

	UPROPERTY(meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsTornado Tornado;

 	UPROPERTY(meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsSword Sword;

 	UPROPERTY(meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsRailSword RailSword;

 	UPROPERTY(meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsGrab Grab;
};

UCLASS(Meta = (ComposeSettingsOnto = "USwarmBehaviourSettings"))
class USwarmBehaviourRailSwordSettings : USwarmBehaviourBaseSettings
{
  	UPROPERTY(Category = "RailSword", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsRailSword RailSword;

	default Shape = ESwarmShape::RailSword;
};

UCLASS(Meta = (ComposeSettingsOnto = "USwarmBehaviourSettings"))
class USwarmBehaviourSwordSettings : USwarmBehaviourBaseSettings
{
  	UPROPERTY(Category = "Sword", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsSword Sword;

	default Shape = ESwarmShape::Sword;
};

UCLASS(Meta = (ComposeSettingsOnto = "USwarmBehaviourSettings"))
class USwarmBehaviourGrabSettings : USwarmBehaviourBaseSettings
{
  	UPROPERTY(Category = "Grab", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsGrab Grab;

	default Shape = ESwarmShape::HandGrab;
};

UCLASS(Meta = (ComposeSettingsOnto = "USwarmBehaviourSettings"))
class USwarmBehaviourHammerSettings : USwarmBehaviourBaseSettings
{
  	UPROPERTY(Category = "Hammer", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsHammer Hammer;

	default Shape = ESwarmShape::Hammer;
};

UCLASS(meta = (ComposeSettingsOnto = "USwarmBehaviourSettings"))
class USwarmBehaviourHitAndRunSettings : USwarmBehaviourBaseSettings
{
  	UPROPERTY(Category = "HitAndRun", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsHitAndRun HitAndRun;

	default Shape = ESwarmShape::Airplane;
};

UCLASS(meta = (ComposeSettingsOnto = "USwarmBehaviourSettings"))
class USwarmBehaviourSlideSettings : USwarmBehaviourBaseSettings
{
  	UPROPERTY(Category = "Slide", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsSlide Slide;

	default Shape = ESwarmShape::Slide;
};

UCLASS(meta = (ComposeSettingsOnto = "USwarmBehaviourSettings"))
class USwarmBehaviourSoloShieldSettings : USwarmBehaviourBaseSettings
{
  	UPROPERTY(Category = "Shield", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsSoloShield SoloShield;

	default Shape = ESwarmShape::Shield;
};

UCLASS(meta = (ComposeSettingsOnto = "USwarmBehaviourSettings"))
class USwarmBehaviourSoloHandSmashSettings : USwarmBehaviourBaseSettings
{
  	UPROPERTY(Category = "Hand", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsSoloHandSmash SoloHandSmash;

	default Shape = ESwarmShape::RightHand;
};

UCLASS(meta = (ComposeSettingsOnto = "USwarmBehaviourSettings"))
class USwarmBehaviourTornadoSettings : USwarmBehaviourBaseSettings
{
  	UPROPERTY(Category = "Tornado", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsTornado Tornado;

	default Shape = ESwarmShape::Tornado;
};

UCLASS(Abstract, meta = (ComposeSettingsOnto = "USwarmBehaviourSettings"))
class USwarmBehaviourBaseSettings : UHazeComposableSettings
{
	// Just base class so that the DropDown only shows swarm assets. 
  	UPROPERTY(Category = "Base")
	ESwarmShape Shape = ESwarmShape::None;
};

//////////////////////////////////////////////////////////////////////////
// SoloHandSmash
USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsSoloHandSmash
{
  	UPROPERTY(Category = "SoloHandSmash", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsSoloHandSmashIdle Idle;

  	UPROPERTY(Category = "SoloHandSmash", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsSoloHandSmashGentleman Gentleman;

  	UPROPERTY(Category = "SoloHandSmash", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsSoloHandSmashTelegraphInitial TelegraphInitial;

  	UPROPERTY(Category = "SoloHandSmash", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsSoloHandSmashAttack Attack;

  	UPROPERTY(Category = "SoloHandSmash", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsSoloHandSmashTelegraphBetweenAttacks TelegraphBetween;
}

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsSoloHandSmashIdle
{
	UPROPERTY(Category = "Idle")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsSoloHandSmashGentleman
{
	UPROPERTY(Category = "Gentleman")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsSoloHandSmashTelegraphInitial
{
	UPROPERTY(Category = "TelegraphInitial")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	UPROPERTY(Category = "TelegraphInitial")
	float TelegraphingTime = 2.5f;

	// relative to queen and victim 
	UPROPERTY(Category = "TelegraphInitial")
	FVector TelegraphOffset = FVector(0.f, 500.f, 0.f);

	/* How fast we should rotate towards the player while telegraphing */
	UPROPERTY(Category = "TelegraphInitial")
	float RotateTowardsPlayerSpeed = 3.f;
	bool bInterpConstantSpeed = false;

	// Swarm will abort the attack if it explodes within this time 
	// time window after switching to this attack state. Unit: seconds.
	UPROPERTY(Category = "Attack")
	float AbortAttackWithinTimeWindow = 1.1f;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsSoloHandSmashTelegraphBetweenAttacks
{
	UPROPERTY(Category = "TelegraphBetween")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	// How long the swarm has to wait for another attack 
	// Animation blend in time. You generally want this 
	// to be == 'TimeBetweenAttacks' 
	UPROPERTY(Category = "TelegraphBetween")
    float BlendInTime = 0.5f;

	// How long the swarm has to wait for another attack 
	UPROPERTY(Category = "TelegraphBetween")
    float TimeBetweenAttacks = 0.5f;

	// relative to swarm and victim
	UPROPERTY(Category = "TelegraphBetween")
	FVector TelegraphOffset = FVector::ZeroVector;

	/* Switch player to attack, between attacks. */ 
	UPROPERTY(Category = "TelegraphAttack")
	bool bSwitchPlayerVictimBetweenAttacks = false;

	/* How fast we should rotate towards the player while telegraphing */
	UPROPERTY(Category = "TelegraphBetween")
	float RotateTowardsPlayerSpeed = 3.f;
	bool bInterpConstantSpeed = false;

	// Swarm will abort the attack if it explodes within this time 
	// time window after switching to this attack state. Unit: seconds.
	UPROPERTY(Category = "TelegraphBetween")
	float AbortAttackWithinTimeWindow = 1.1f;
}

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsSoloHandSmashAttack
{
	UPROPERTY(Category = "Attack")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;
//
//	// Length of the attack animation (used instead of AnimNotifies)
//	UPROPERTY(Category = "Attack")
//	float AttackDuration = 1.5f;

	// How long we should keep track of the victim, while performing the attack.
	UPROPERTY(Category = "Attack")
	float KeepTrackOfVictimDuration = 0.3f;

	// how many attacks the swarm performs without interruption.
	UPROPERTY(Category = "Attack")
	int32 NumConsecutiveAttacks = 3;

	// how many attack the swarm performs before going into recover.
	UPROPERTY(Category = "Attack")
	int32 NumTotalAttacks = 6;

	// While keeping track of the player, how fast we should rotate and follow
	UPROPERTY(Category = "Attack")
	float SpringToLocationStiffness = 10.f;

	// controls oscillation amount. 1 == no oscillation, 0 == max oscillation amount. 
	UPROPERTY(Category = "Attack" , meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float SpringToLocationDamping = 0.8f;

	UPROPERTY(Category = "Attack")
 	float RotationLerpSpeed = 3.f;
 	bool bConstantLerpSpeed = false;

	// Swarm will abort the attack if it explodes within this time 
	// time window after switching to this attack state. Unit: seconds.
	UPROPERTY(Category = "Attack")
	float AbortAttackWithinTimeWindow = 2.f;
};

//////////////////////////////////////////////////////////////////////////
// SoloShield 

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsSoloShield
{
  	UPROPERTY(Category = "SoloShield", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsSoloShieldIdle Idle;

  	UPROPERTY(Category = "SoloShield", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsSoloShieldTelegraphDefence TelegraphDefence;

  	UPROPERTY(Category = "SoloShield", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsSoloShieldDefendMiddle DefendMiddle;
}

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsSoloShieldIdle
{
	UPROPERTY(Category = "Idle")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsSoloShieldTelegraphDefence
{
	UPROPERTY(Category = "TelegraphDefence")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	// offset is along the vector between the queen and the player 
	UPROPERTY(Category = "TelegraphDefence")
	FVector Offset = FVector(1500.f, 0.f, -250.f);

	// Prevent the shield from tilting by
	// constraining the vector between the queen and player to the world XY plane. 
	UPROPERTY(Category = "TelegraphDefence")
	bool bTangentialToWorldPlane = true;

	UPROPERTY(Category = "TelegraphDefence")
	float TelegraphTime = 3.f;

	UPROPERTY(Category = "TelegraphDefence")
	float LerpSpeed = 3.f;
}

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsSoloShieldDefendMiddle
{
	UPROPERTY(Category = "DefendMiddle")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	// offset is along the vector between the queen and the player 
	UPROPERTY(Category = "DefendMiddle")
	FVector Offset = FVector(1500.f, 0.f, -250.f);

	UPROPERTY(Category = "DefendMiddle")
	float BlendInTime = 0.2f;

	// Prevent the shield from tilting by
	// constraining the vector between the queen and player to the world XY plane. 
	UPROPERTY(Category = "DefendMiddle")
	bool bTangentialToWorldPlane = true;

	UPROPERTY(Category = "DefendMiddle")
	float LerpSpeed = 3.f;

	// // While keeping track of the player, how fast we should rotate and follow
	// UPROPERTY(Category = "DefendMiddle")
	// float SpringToLocationStiffness = 15.f;

	// // controls oscillation amount. 1 == no oscillation, 0 == max oscillation amount. 
	// UPROPERTY(Category = "DefendMiddle" , meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	// float SpringToLocationDamping = 0.6f;
};

//////////////////////////////////////////////////////////////////////////
// Slide 

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsSlide
{
  	UPROPERTY(Category = "Slide", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsSlideIdle Idle;

  	UPROPERTY(Category = "Slide", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsSlidePursueSpline PursueSpline;
}

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsSlideIdle
{
	UPROPERTY(Category = "Idle")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsSlidePursueSpline
{
	UPROPERTY(Category = "Pursue Spline")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	// (Carrot on a stick for the swarm)
	// How accurately the swarm should foklow the spline.
	// low values increase accuracy, high values promote shortcuts. 
	UPROPERTY(Category = "Pursue Spline")
	float InterpStepSize = 3200.f;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsGrab
{
	UPROPERTY(Category = "Animations")
	USwarmAnimationSettingsBaseDataAsset AnimWhileMoving;

	UPROPERTY(Category = "Animations")
	USwarmAnimationSettingsBaseDataAsset GrabAnim;

	UPROPERTY(Category = "Movement")
	float TimeToReachSplinePos = 2.7f;

	UPROPERTY(Category = "Animation")
	float TimeUntilHandStartsClosing = 2.0f;
};

//////////////////////////////////////////////////////////////////////////
// Rail SWORD 

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsRailSword
{
  	UPROPERTY(Category = "Sword", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsRailSwordTelegraphInitialAttack TelegraphInitial;

  	UPROPERTY(Category = "Sword", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsRailSwordAttack Attack;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsRailSwordAttack
{
	UPROPERTY(Category = "Attack")
	UMovementSettings SkyDiveMovementSettings;

	UPROPERTY(Category = "Attack")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	// While keeping track of the player, how fast we should rotate and follow
	UPROPERTY(Category = "Attack")
	float SpringToLocationStiffness = 55.f;

	// controls oscillation amount. 1 == no oscillation, 0 == max oscillation amount. 
	UPROPERTY(Category = "Attack" , meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float SpringToLocationDamping = 0.8f;

	UPROPERTY(Category = "Attack")
	float AttackSpeed = 2000.f;

	// Used to cancel the attack earlier when approaching the end 
	UPROPERTY(Category = "Attack")
	float CloseEnoughToEndDist = 1500.f;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsRailSwordTelegraphInitialAttack
{
	UPROPERTY(Category = "TelegraphAttack")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	UPROPERTY(Category = "TelegraphAttack")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAssetEnter;

	UPROPERTY(Category = "TelegraphAttack")
	float MinDistancePlayerHasToTraveledOnSpline = 1000.f;

	/* How long the blend to the Sword animation should be. */
	UPROPERTY(Category = "TelegraphAttack")
	float TelegraphingTime = 2.f;

	/* How long until we switch to attack capability */
	UPROPERTY(Category = "TelegraphAttack")
	float TimeUntilWeSwitchState = 5.f;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsRailSwordShieldDefendMiddle
{
	UPROPERTY(Category = "DefendMiddle")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	// offset is along the vector between the queen and the player 
	UPROPERTY(Category = "DefendMiddle")
	FVector Offset = FVector(1500.f, 0.f, -250.f);

	// time to Transition from sword to shield
	UPROPERTY(Category = "DefendMiddle")
	float BlendInTime = 5.5f;

	// Prevent the shield from tilting by
	// constraining the vector between the queen and player to the world XY plane. 
	UPROPERTY(Category = "DefendMiddle")
	bool bTangentialToWorldPlane = true;

	// While keeping track of the player, how fast we should rotate and follow
	UPROPERTY(Category = "DefendMiddle")
	float SpringToLocationStiffness = 5.f;

	// controls oscillation amount. 1 == no oscillation, 0 == max oscillation amount. 
	UPROPERTY(Category = "DefendMiddle" , meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float SpringToLocationDamping = 0.6f;
};

//////////////////////////////////////////////////////////////////////////
// SWORD 

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsSword
{
  	UPROPERTY(Category = "Sword", meta = (ShowOnlyInnerProperties, ComposedStruct))
 	FSwarmSettingsSwordIdle Idle;

  	UPROPERTY(Category = "Sword", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsSwordTelegraphInitialAttack TelegraphInitial;

  	UPROPERTY(Category = "Sword", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsSwordTelegraphBetweenAttacks TelegraphBetween;

  	UPROPERTY(Category = "Sword", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsSwordAttack Attack;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsSwordIdle
{
	UPROPERTY(Category = "Idle")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsSwordTelegraphInitialAttack
{
	UPROPERTY(Category = "TelegraphAttack")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	/* How long the blend to the Sword animation should be. */
	UPROPERTY(Category = "TelegraphAttack")
	float TelegraphingTime = 2.f;

	UPROPERTY(Category = "TelegraphAttack")
	FVector TelegraphOffset = FVector(0.f, 0.f, 0.f);

	/* How fast we should rotate towards the player while telegraphing */
	UPROPERTY(Category = "TelegraphAttack")
 	float RotateTowardsPlayerSpeed = 3.f;
 	bool bInterpConstantSpeed = false;

	// Swarm will abort the attack if it explodes within this time 
	// time window after switching to this attack state. Unit: seconds.
	UPROPERTY(Category = "TelegraphAttack")
	float AbortAttackWithinTimeWindow = 1.1f;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsSwordTelegraphBetweenAttacks
{
	UPROPERTY(Category = "TelegraphAttack")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	// How long the swarm has to wait for another attack 
	UPROPERTY(Category = "TelegraphAttack")
    float TimeBetweenAttacks = 0.5f;

	/* Switch player to attack, between attacks. */ 
	UPROPERTY(Category = "TelegraphAttack")
	bool bSwitchPlayerVictimBetweenAttacks = true;

	/* How fast we should rotate towards the player while telegraphing */
	UPROPERTY(Category = "TelegraphAttack")
 	float RotateTowardsPlayerSpeed = 3.f;
 	bool bInterpConstantSpeed = false;

	// Swarm will abort the attack if it explodes within this time 
	// time window after switching to this attack state. Unit: seconds.
	UPROPERTY(Category = "TelegraphAttack")
	float AbortAttackWithinTimeWindow = 1.1f;
}

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsSwordAttack
{
	UPROPERTY(Category = "Attack")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	UPROPERTY(Category = "Attack")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset_LeftSlash;

	// How long we should keep track of the victim, while performing the attack.
	UPROPERTY(Category = "Attack")
	float KeepTrackOfVictimDuration = 0.3f;

	// how many attacks the swarm performs without interruption.
	UPROPERTY(Category = "Attack")
	int32 NumConsecutiveAttacks = 3;

	// how many attack the swarm performs before going into recover.
	UPROPERTY(Category = "Attack")
	int32 NumTotalAttacks = 6;

	// While keeping track of the player, how fast we should rotate and follow
	UPROPERTY(Category = "Attack")
	float SpringToLocationStiffness = 10.f;

	// controls oscillation amount. 1 == no oscillation, 0 == max oscillation amount. 
	UPROPERTY(Category = "Attack" , meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float SpringToLocationDamping = 0.8f;

	UPROPERTY(Category = "Attack")
 	float RotationLerpSpeed = 3.f;
 	bool bConstantLerpSpeed = false;

	// Swarm will abort the attack if it explodes within this time 
	// time window after switching to this attack state. Unit: seconds.
	UPROPERTY(Category = "Attack")
	float AbortAttackWithinTimeWindow = 2.f;
};

//////////////////////////////////////////////////////////////////////////
// HAMMER 

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsHammer
{
  	UPROPERTY(Category = "Hammer", meta = (ShowOnlyInnerProperties, ComposedStruct))
 	FSwarmSettingsHammerIdle Idle;
 
  	UPROPERTY(Category = "Hammer", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsHammerSearch Search;

  	UPROPERTY(Category = "Hammer", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsHammerPursueSpline PursueSpline;

  	UPROPERTY(Category = "Hammer", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsHammerPursueMiddle PursueMiddle;

  	UPROPERTY(Category = "Hammer", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsHammerGentleman Gentleman;

  	UPROPERTY(Category = "Hammer", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsHammerTelegraphInitialAttack TelegraphInitial;

  	UPROPERTY(Category = "Hammer", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsHammerTelegraphBetweenAttacks TelegraphBetween;

  	UPROPERTY(Category = "Hammer", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsHammerAttack Attack;

  	UPROPERTY(Category = "Hammer", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsHammerRecover Recover;

  	UPROPERTY(Category = "Hammer", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsHammerAttackUltimate AttackUltimate;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsHammerIdle
{
	UPROPERTY(Category = "Idle")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsHammerSearch
{
	UPROPERTY(Category = "Search")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	// (Carrot on a stick for the swarm)
	// How accurately the swarm should follow the spline.
	// low values increase accuracy, high values promote shortcuts. 
	UPROPERTY(Category = "Search")
	float InterpStepSize = 1500.f;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsHammerPursueSpline
{
	UPROPERTY(Category = "Pursue")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	// How long we have to stay in this state until we
	// can transition to the other state.
	UPROPERTY(Category = "Pursue")
	float TimeSpentInPursuit = 1.f;

	// we'll randomize a certain percetage. Range 0 to 1
	UPROPERTY(Category = "Pursue" , meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float TimeRandomizedFraction = 0.f;

	// (Carrot on a stick for the swarm)
	// How accurately the swarm should follow the spline.
	// low values increase accuracy, high values promote shortcuts. 
	UPROPERTY(Category = "Pursue")
	float InterpStepSize = 2000.f;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsHammerPursueMiddle
{
	UPROPERTY(Category = "Pursue")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	UPROPERTY(Category = "Pursue")
	float TimeToReachMiddle = 2.f;

//	UPROPERTY(Category = "Pursue")
//	float CloseEnoughRadius = 100.f;

	UPROPERTY(Category = "Pursue")
	FVector OffsetFromMiddle = FVector(0.f, 0.f, 1000.f);
}

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsHammerGentleman
{
	UPROPERTY(Category = "Gentleman")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsHammerTelegraphInitialAttack
{
	UPROPERTY(Category = "TelegraphInitialAttack")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	// Time until we switch to Attack
	UPROPERTY(Category = "TelegraphInitialAttack")
	float TelegraphingTime = 2.f;

	/* How long the blend to the Hammer animation should be. */
	UPROPERTY(Category = "TelegraphInitialAttack")
	float BlendInTime = 2.f;

	UPROPERTY(Category = "TelegraphInitialAttack")
	FVector AdditionalOffset = FVector(0.f, 0.f, 0.f);

	/* How fast we should rotate towards the player while telegraphing */
	UPROPERTY(Category = "TelegraphInitialAttack")
 	float RotateTowardsPlayerSpeed = 10.f;

	UPROPERTY(Category = "TelegraphInitialAttack", DisplayName = "LerpTowardsPlayerSpeed")
 	float LerpTowardsMiddleSpeed = 1.5f;

	UPROPERTY(Category = "TelegraphInitialAttack")
 	bool bInterpConstantSpeed = false;

	// Swarm will abort the attack if it explodes within this time 
	// time window after switching to this attack state. Unit: seconds.
	UPROPERTY(Category = "TelegraphInitialAttack")
	float AbortAttackWithinTimeWindow = 0.1f;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsHammerTelegraphBetweenAttacks
{
	UPROPERTY(Category = "TelegraphBetweenAttacks")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	/* How long the swarm has to wait for another attack 
		Also accounts as a time used for animation blend in 
		and also how long it should take to reach the desired location */
	UPROPERTY(Category = "TelegraphBetweenAttacks")
    float TimeBetweenAttacks = 0.5f;

	/* Switch player to attack, between attacks. */ 
	UPROPERTY(Category = "TelegraphBetweenAttacks")
	bool bSwitchPlayerVictimBetweenAttacks = true;

	/* Either we reach the target with time or with this lerp speed 
		any values > 0 will override arrival by time behaviour */
	UPROPERTY(Category = "TelegraphBetweenAttacks")
	float MoveWithConstantLerpSpeed = -1.f;

	/* How fast we should rotate towards the player while telegraphing */
	UPROPERTY(Category = "TelegraphBetweenAttacks")
 	float RotateTowardsPlayerSpeed = 2.f;
 	bool bInterpConstantSpeed = false;

	// Swarm will abort the attack if it explodes within this time 
	// time window after switching to this attack state. Unit: seconds.
	UPROPERTY(Category = "TelegraphBetweenAttacks")
	float AbortAttackWithinTimeWindow = 0.1f;

	UPROPERTY(Category = "TelegraphBetweenAttacks")
	FVector AdditionalOffset = FVector(0.f, 0.f, 0.f);
}

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsHammerAttack
{
	UPROPERTY(Category = "Attack")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	// How long we should keep track of the victim, while performing the attack.
	UPROPERTY(Category = "Attack")
	float KeepTrackOfVictimDuration = 0.3f;

	// how many attacks the swarm performs without interruption.
	UPROPERTY(Category = "Attack")
	int32 NumConsecutiveAttacks = 3;

	// how many attack the swarm performs before going into recover.
	UPROPERTY(Category = "Attack")
	int32 NumTotalAttacks = 6;

	// While keeping track of the player, how fast we should rotate and follow
	UPROPERTY(Category = "Attack")
 	float LerpSpeed = 2.f;
 	bool bConstantLerpSpeed = false;

	// Swarm will abort the attack if it explodes within this time 
	// time window after switching to this attack state. Unit: seconds.
	UPROPERTY(Category = "Attack")
	float AbortAttackWithinTimeWindow = 2.f;

	/* Swarm will switch between the players when they are 
	 within this distance of each other */
	UPROPERTY(Category = "Attack")
	float AlternateVictimDistanceBetweenPlayers = 0.f;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsHammerAttackUltimate
{
	UPROPERTY(Category = "Attack")
	USwarmAnimationSettingsBaseDataAsset TelegraphAnim;

	UPROPERTY(Category = "Attack")
	float TelegraphTime = 6.f;

	UPROPERTY(Category = "Attack")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	// For movement and animation
	UPROPERTY(Category = "Attack")
	float BlendInTime = 1.0f;

	UPROPERTY(Category = "Attack")
	USwarmAnimationSettingsBaseDataAsset PummelAnim;

	UPROPERTY(Category = "Attack")
	float BlendInTimePummel = 1.0f;
}

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsHammerRecover
{
	UPROPERTY(Category = "Recover")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	UPROPERTY(Category = "Recover")
 	float BlendInTime = 0.f;

 	bool bInterpolateSwarmWithConstantSpeed = false;

	UPROPERTY(Category = "Recover")
 	float InterpolationSpeed_Swarm = 1.f;

	UPROPERTY(Category = "Recover")
	FVector RestingOffset = FVector(1500.f, 0.f, 1500.f);

	UPROPERTY(Category = "Recover")
	float TimeSpentRecovering = 1.337f;
};

//////////////////////////////////////////////////////////////////////////
// Tornado Attack 

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsTornado
{
  	UPROPERTY(Category = "Tornado", meta = (ShowOnlyInnerProperties, ComposedStruct))
 	FSwarmSettingsTornadoIdle Idle;

  	UPROPERTY(Category = "Tornado", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsTornadoPursueSpline PursueSpline;

  	UPROPERTY(Category = "Tornado", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsTornadoPursuePlayer PursuePlayer;

  	UPROPERTY(Category = "Tornado", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsTornadoCirclePlayer CirclePlayer;

  	UPROPERTY(Category = "Tornado", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsTornadoAttackPlayer Attack;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsTornadoAttackPlayer
{
	UPROPERTY(Category = "Attack")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	// The ideal attack duration. 
	UPROPERTY(Category = "Attack")
	float TimeSpentAttacking_MAX = 1.5f;

	// Will abort attack if swarm explodes after this duration.
	UPROPERTY(Category = "Attack")
	float TimeSpentAttacking_MIN = 1.f;

	// How long we should keep track of the victims 
	// transform while performing the attack.
	UPROPERTY(Category = "Attack")
	float KeepTrackOfVictimDuration = 0.3f;

	// how many attack the swarm performs before going into recover.
	UPROPERTY(Category = "Attack")
	int32 NumTotalAttacks = 6;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsTornadoIdle
{
	UPROPERTY(Category = "Idle")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	UPROPERTY(Category = "Idle")
	float TelegraphTime = 0.5f;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsTornadoPursueSpline
{
	UPROPERTY(Category = "Pursue")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	UPROPERTY(Category = "Pursue")
	float BaseSpeed = 3200.f;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsTornadoCirclePlayer
{
	UPROPERTY(Category = "Circle")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	// How long we should circle the player until we start our attack
	UPROPERTY(Category = "Circle")
	float TimeSpentCircling_MAX = 5.f;

	// We'll circle the player for at least this amount of time. 
	UPROPERTY(Category = "Circle")
	float TimeSpentCircling_MIN = 2.f;

	// (Carrot on a stick for the swarm)
	// How accurately the swarm should follow the spline.
	// low values increase accuracy, high values promote shortcuts. 
	UPROPERTY(Category = "Circle")
	float InterpStepSize = 2000.f;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsTornadoPursuePlayer
{
	UPROPERTY(Category = "Pursue")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	// HSow close we need to be to the player before we enter new state.
	UPROPERTY(Category = "Pursue")
 	float CloseEnoughToPlayerRadius = 15000.f;

	// (Carrot on a stick for the swarm)
	// How accurately the swarm should follow the spline.
	// low values increase accuracy, high values promote shortcuts. 
	UPROPERTY(Category = "Pursue")
	float InterpStepSize = 1500.f;
};

//////////////////////////////////////////////////////////////////////////
// HIT N' RUN

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsHitAndRun
{
//   	UPROPERTY(Category = "Idle", meta = (ShowOnlyInnerProperties, ComposedStruct))
  	UPROPERTY(Category = "HitAndRun", meta = (ShowOnlyInnerProperties, ComposedStruct))
 	FSwarmSettingsHitAndRunIdle Idle;

  	UPROPERTY(Category = "HitAndRun", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsHitAndRunPursueSpline PursueSpline;
 
  	UPROPERTY(Category = "HitAndRun", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsHitAndRunPursuePlayer PursuePlayer;

  	UPROPERTY(Category = "HitAndRun", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsHitAndRunCirclePlayer CirclePlayer;

  	UPROPERTY(Category = "HitAndRun", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsHitAndRunTelegraphAttack TelegraphInitial;

  	UPROPERTY(Category = "HitAndRun", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsHitAndRunTelegraphBetweenAttacks TelegraphBetween;

  	UPROPERTY(Category = "HitAndRun", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsHitAndRunAttack Attack;

  	UPROPERTY(Category = "HitAndRun", meta = (ShowOnlyInnerProperties, ComposedStruct))
	FSwarmSettingsHitAndRunAttackUltimate AttackUltimate;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsHitAndRunIdle
{
	UPROPERTY(Category = "Idle")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsHitAndRunSearch
{
	UPROPERTY(Category = "Search")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	// (Carrot on a stick for the swarm)
	// How accurately the swarm should follow the spline.
	// low values increase accuracy, high values promote shortcuts. 
	UPROPERTY(Category = "Search")
	float InterpStepSize = 4000.f;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsHitAndRunPursueSpline
{
	UPROPERTY(Category = "Pursue")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	// will try to switch to next state once the player is close enough
	UPROPERTY(Category = "Pursue")
 	float CloseEnoughToPlayerRadius = 5000.f;

	UPROPERTY(Category = "Pursue")
	float FollowSplineSpeed = 2000.f;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsHitAndRunPursuePlayer
{
	UPROPERTY(Category = "Pursue")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	// How close we need to be to the player before we enter new state.
	UPROPERTY(Category = "Pursue")
 	float CloseEnoughToPlayerRadius = 5000.f;

	// How fast the swarm can go forwards
	UPROPERTY(Category = "Pursue")
 	float MaxSpeed = 5000.f;

	// Increasing the value will make the swarm turn faster
	UPROPERTY(Category = "Pursue")
 	float MaxAcceleration = 2500.f;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsHitAndRunCirclePlayer
{
	UPROPERTY(Category = "Circle")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	// How long we should circle the player until we start our attack
	UPROPERTY(Category = "Circle")
	float TimeSpentCircling_MAX = 5.f;

	// We'll circle the player for at least this amount of time. 
	UPROPERTY(Category = "Circle")
	float TimeSpentCircling_MIN = 2.f;

	// (Carrot on a stick for the swarm)
	// How accurately the swarm should follow the spline.
	// low values increase accuracy, high values promote shortcuts. 
	UPROPERTY(Category = "Circle")
	float InterpStepSize = 2000.f;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsHitAndRunTelegraphAttack
{
	UPROPERTY(Category = "TelegraphAttack")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	UPROPERTY(Category = "TelegraphAttack")
	float AnimBlendInTime = 2.f;

	UPROPERTY(Category = "TelegraphAttack")
	float DesiredStateDuration = 2.f;

	// Offset relative to Closest transform on spline, while facing the player.
	UPROPERTY(Category = "TelegraphAttack")
	FVector TelegraphingOffset = FVector(0.f, 0.f, 500.f);
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsHitAndRunTelegraphBetweenAttacks
{
	UPROPERTY(Category = "TelegraphAttack")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	// How long the swarm has to wait for another attack 
	UPROPERTY(Category = "TelegraphAttack")
	float TelegraphingTime = 2.f;

	// Offset relative to Closest transform on spline, while facing the player.
	UPROPERTY(Category = "TelegraphAttack")
	FVector TelegraphingOffset = FVector(0.f, 0.f, 500.f);

	/* Switch player to attack, between attacks. */ 
	UPROPERTY(Category = "TelegraphAttack")
	bool bSwitchPlayerVictimBetweenAttacks = true;
}

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsHitAndRunAttack
{
	UPROPERTY(Category = "Attack")
	float ImpulseMagnitude = 4000.f;

	UPROPERTY(Category = "Attack")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	// The ideal attack duration. 
	UPROPERTY(Category = "Attack")
	float TimeSpentAttacking_MAX = 1.5f;

	// Will abort attack if swarm explodes after this duration.
	UPROPERTY(Category = "Attack")
	float TimeSpentAttacking_MIN = 1.f;

	UPROPERTY(Category = "Attack")
	float AnimBlendInTime = 4.f;

	// How long we should keep track of the victims 
	// transform while performing the attack.
	UPROPERTY(Category = "Attack")
	float KeepTrackOfVictimDuration = 0.3f;

	// how many attack the swarm performs before going into recover.
	UPROPERTY(Category = "Attack")
	int32 NumTotalAttacks = 6;
};

USTRUCT(Meta = (ComposedStruct))
struct FSwarmSettingsHitAndRunAttackUltimate
{
	UPROPERTY(Category = "Attack Ultimate")
	USwarmAnimationSettingsBaseDataAsset AnimSettingsDataAsset;

	// The ideal attack duration. 
	UPROPERTY(Category = "Attack Ultimate")
	float TimeSpentAttacking_MAX = 8.5f;

	// Will abort attack if swarm explodes after this duration.
	UPROPERTY(Category = "Attack Ultimate")
	float TimeSpentAttacking_MIN = 1.f;

	UPROPERTY(Category = "Attack Ultimate")
	float Cooldown = 15.f;

};

