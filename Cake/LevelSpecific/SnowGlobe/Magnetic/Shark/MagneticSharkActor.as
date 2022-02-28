// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticSharkComponent;
// import Vino.Movement.Components.MovementComponent;
// import Peanuts.Spline.SplineActor;


// UCLASS(Abstract)
// class AMagneticSharkActor : AHazeActor
// {
// 	UPROPERTY(DefaultComponent, RootComponent)
// 	USceneComponent RootComp;

// 	UPROPERTY(DefaultComponent, Attach = RootComp)
// 	UStaticMeshComponent Base;

// 	UPROPERTY(DefaultComponent, Attach = Base)
// 	UStaticMeshComponent Mesh;
	
// 	UPROPERTY(DefaultComponent, Attach = RootComp)
// 	UMagneticSharkComponent MagnetComponent;

// 	UPROPERTY(DefaultComponent, Attach = RootComp)
// 	USceneComponent  VisionRoot;

// 	UPROPERTY(DefaultComponent, Attach = VisionRoot)
// 	UStaticMeshComponent  VisionCone;

// 	UPROPERTY(DefaultComponent)
// 	UHazeMovementComponent MovementComponent;

// 	UPROPERTY(DefaultComponent, Attach = Base)
// 	UCapsuleComponent  CapsuleCollider;

// 	UPROPERTY()
// 	ASplineActor SplineToFollow;

// 	AHazePlayerCharacter TargetPlayer;

// 	EMagneticSharkState CurrentState;
// 	FVector Velocity; 
// 	float AttackAcceleration = 1500.f;
// 	float SearchSpeed; 
// 	float Drag = 0.7f; 
	
// 	bool bAffectedByMagnet = false;
	
	
// 	UPROPERTY()
// 	TSubclassOf<UHazeCapability> RequiredCapability;

// 	UFUNCTION(BlueprintOverride)
// 	void BeginPlay()
// 	{
// 		CurrentState = EMagneticSharkState::Searching;

// 		MovementComponent.Setup(CapsuleCollider);

// 		Capability::AddPlayerCapabilityRequest(RequiredCapability.Get());

// 		AddCapability(n"MagneticSharkSearchCapability");
// 		AddCapability(n"MagneticSharkAttackCapability");
// 		AddCapability(n"MagneticSharkAffectedByMagnetCapability");
// 		AddCapability(n"MagneticSharkSpotLightCapability");

// 	}

// 	UFUNCTION(BlueprintOverride)
//     void EndPlay(EEndPlayReason Reason)
// 	{
// 		Capability::RemovePlayerCapabilityRequest(RequiredCapability.Get());
// 	}
// }

// enum EMagneticSharkState
// {
// 	Searching,
// 	Attacking,
// 	Fleeing
// } 
