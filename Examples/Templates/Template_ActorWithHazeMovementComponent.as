import Vino.Movement.Components.MovementComponent;

settings TemplateDefaultMovementSettings for UMovementSettings
{
	TemplateDefaultMovementSettings.MoveSpeed = 400.f;
	TemplateDefaultMovementSettings.GravityMultiplier = 3.f;
	TemplateDefaultMovementSettings.ActorMaxFallSpeed = 1800.f;
	TemplateDefaultMovementSettings.StepUpAmount = 40.f;
	TemplateDefaultMovementSettings.CeilingAngle = 30.f;
	TemplateDefaultMovementSettings.WalkableSlopeAngle = 55.f;
	TemplateDefaultMovementSettings.AirControlLerpSpeed = 2500.f;
	TemplateDefaultMovementSettings.GroundRotationSpeed = 20.f;
	TemplateDefaultMovementSettings.AirRotationSpeed = 10.f;
	TemplateDefaultMovementSettings.VerticalForceAirPushOffThreshold = 500.f;
}

class ATemplateActorWithHazeMovementComponent : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.DefaultMovementSettings = TemplateDefaultMovementSettings;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent CapsuleComponent;
	default CapsuleComponent.SetCollisionProfileName(n"BlockAll"); // Should probably be changed to something more specific.
	default CapsuleComponent.SetCapsuleHalfHeight(100.f);
	default CapsuleComponent.SetCapsuleRadius(65.f);

	// UPROPERTY(DefaultComponent)
	// USphereComponent SphereComponent;
	// default SphereComponent.SetCollisionProfileName(n"BlockAll"); // Should probably be changed to something more specific.
	// default SphereComponent.SetSphereRadius(150.f);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp.Setup(CapsuleComponent);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FHazeFrameMovement HackMove = MoveComp.MakeFrameMovement(n"GiveMeAName");
		MoveComp.Move(HackMove);
	}
}