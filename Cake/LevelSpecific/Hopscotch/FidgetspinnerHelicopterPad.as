import Cake.LevelSpecific.Hopscotch.FidgetspinnerLandingpad;
import Cake.LevelSpecific.Hopscotch.FidgetSpinner;

event void FPadLoweredSignature();

class AFidgetspinnerHelicopterPad : AFidgetspinnerLandingpad
{
	UPROPERTY(DefaultComponent, Attach = Mesh)
	UStaticMeshComponent PillarMesh;
	default PillarMesh.RelativeLocation = FVector(0.f, 0.f, -290.f);
	default PillarMesh.RelativeScale3D = FVector(4.f, 4.f, 6.f);

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UTextRenderComponent TextComp;
	default TextComp.RelativeLocation = FVector(0.f, 0.f, 12.f);
	default TextComp.RelativeScale3D = FVector(8.5f, 55.5f, 8.5f);
	default TextComp.Text = FText::FromString("H");
	default TextComp.HorizontalAlignment = EHorizTextAligment::EHTA_Center;
	default TextComp.VerticalAlignment = EVerticalTextAligment::EVRTA_TextCenter;

	UPROPERTY()
	FHazeTimeLike LowerPadTimeline;
	default LowerPadTimeline.Duration = 2.5f;

	UPROPERTY(meta = (MakeEditWidget))
	FVector TargetLocation;

	FVector InitialLocation;

	UPROPERTY()
	FPadLoweredSignature PadLoweredEvent;

	bool bHasBeenActivated;

	default Mesh.RelativeScale3D = FVector(0.6f, 0.6f, 5.f);
	default BoxCollision.RelativeLocation = FVector(0.f, 0.f, 12.f);
	default BoxCollision.BoxExtent = FVector(780.f, 780.f, 9.f);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AFidgetspinnerLandingpad::BeginPlay_Implementation();

		BoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnBoxCollisionBeginOverlap");
		LowerPadTimeline.BindUpdate(this, n"LowerPadTimelineUpdate");
		LowerPadTimeline.BindFinished(this, n"LowerPadTimelineFinished");

		InitialLocation = Mesh.RelativeLocation;
	}

	UFUNCTION()
	void LowerPadTimelineUpdate(float CurrentValue)
	{
		Mesh.SetRelativeLocation(FMath::VLerp(InitialLocation, TargetLocation, FVector(CurrentValue, CurrentValue, CurrentValue)));
	}

	UFUNCTION()
	void LowerPadTimelineFinished(float CurrentValue)
	{
		PadLoweredEvent.Broadcast();
	}

	UFUNCTION()
	void OnBoxCollisionBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{	
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr && !bHasBeenActivated)
		{
			bHasBeenActivated = true;
			LowerPadTimeline.PlayFromStart();
			return;
		} 
		
		AFidgetSpinner Fidget = Cast<AFidgetSpinner>(OtherActor);
		
		if (Fidget != nullptr)
		{
			Fidget.AttachToActor(this);
		}
	}
}