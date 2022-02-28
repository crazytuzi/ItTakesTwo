import Vino.Interactions.InteractionComponent;

event void FRotatingLeverSignature(float Value);
event void FRotatingLeverInteractionStateChangedSignature(AHazePlayerCharacter player);

class ARotatingLever : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent BaseMesh;
	default BaseMesh.RelativeLocation = FVector(0.f, 0.f, 0.f);
	default BaseMesh.RelativeRotation = FRotator(0.f, 0.f, 0.f);
	default BaseMesh.RelativeScale3D = FVector(1.f, 1.f, 1.f);
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent LeverMesh;
	default LeverMesh.RelativeRotation = FRotator(0.f, 0.f, 0.f);
	default LeverMesh.RelativeScale3D = FVector(1.f, 1.f, 1.f);

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UInteractionComponent InteractionComp;
	default InteractionComp.RelativeLocation = FVector(0.f, 0.f, 0.f);
	default InteractionComp.RelativeRotation = FRotator(0.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent HourHand;
	default HourHand.RelativeScale3D = FVector(1.f, 6.f, 6.f);
	default HourHand.RelativeLocation = FVector(0.f, 0.f, -30.f);
	default HourHand.RelativeRotation = FRotator(90.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent MinuteHand;
	default MinuteHand.RelativeScale3D = FVector(1.f, 6.f, 6.f);
	default MinuteHand.RelativeLocation = FVector(0.f, 0.f, -30.f);
	default MinuteHand.RelativeRotation = FRotator(90.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent)
	USceneComponent POIActor;

	UPROPERTY()
	FRotatingLeverSignature LeverValueChanged;

	UPROPERTY()
	FRotatingLeverInteractionStateChangedSignature PlayerLeft;

	UPROPERTY()
	FRotatingLeverInteractionStateChangedSignature PlayerStartedInteracting;

	UPROPERTY()
	UAnimSequence AnimationToUse;

	UPROPERTY()
	float RotationSpeed = 60.f;


	float RotationMultiplier;
	float LeverRotationValue;
	float LeverRotationTarget;
	float MaxRotation = 80.f;
	float Yaw = 180.f;

	bool bInCurrentTime = true;

	AHazePlayerCharacter PlayerUsingLever;

	UPROPERTY()
	AStaticMeshActor CurrentTimeDoor;

	UPROPERTY()
	AStaticMeshActor PastTimeDoor;

	FVector CurrentTimeDoorStartLoc;
	FVector PastTimeDoorStartLoc;

	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetCurrentPlayerUsingLever()
	{
		return PlayerUsingLever;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnActivated.AddUFunction(this, n"LeverActivated");
		CurrentTimeDoorStartLoc = CurrentTimeDoor.ActorLocation;
		PastTimeDoorStartLoc = PastTimeDoor.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float Delta)
	{
		float YawToAdd;
		float DoorAlpha;

		if (PlayerUsingLever != nullptr)
		{
			YawToAdd = (RotationSpeed * RotationMultiplier) * Delta;
			HourHand.SetRelativeRotation(FRotator(HourHand.RelativeRotation.Pitch, HourHand.RelativeRotation.Yaw - (YawToAdd * 2.5), HourHand.RelativeRotation.Roll));
			MinuteHand.SetRelativeRotation(FRotator(MinuteHand.RelativeRotation.Pitch, MinuteHand.RelativeRotation.Yaw - (YawToAdd * 15.f), MinuteHand.RelativeRotation.Roll));

			Yaw += YawToAdd;
			RotationRoot.SetWorldRotation(FRotator(0.f, Yaw + 180, 0.f));
			if (Yaw > 180)
			{
				DoorAlpha = FMath::Lerp(0.f, 1.f, (Yaw - 180)/180.f);
			}
			else
			{
				DoorAlpha = FMath::Lerp(1.f, 0.f, Yaw/180.f);
			}

			if (bInCurrentTime)
			{
				CurrentTimeDoor.SetActorLocation(FMath::Lerp(CurrentTimeDoorStartLoc, FVector(CurrentTimeDoorStartLoc.X, CurrentTimeDoorStartLoc.Y, CurrentTimeDoorStartLoc.Z + 1000.f), DoorAlpha));
			}
			else
			{
				PastTimeDoor.SetActorLocation(FMath::Lerp(FVector(PastTimeDoorStartLoc.X, PastTimeDoorStartLoc.Y, PastTimeDoorStartLoc.Z - 1000.f), PastTimeDoorStartLoc, DoorAlpha));
			}

			FHazePointOfInterest Poi;
			Poi.FocusTarget.Component = POIActor;
			Poi.Blend.BlendTime = 0.f;
			PlayerUsingLever.ApplyPointOfInterest(Poi, this);

		}

		if (Yaw >= 360.f || Yaw < 0.f)
		{
			bInCurrentTime = !bInCurrentTime;
			TeleportToOtherTimePeriod(bInCurrentTime);
		}

		Yaw = Math::FWrap(Yaw, 0.f, 360.f);
		// Print(""+DoorAlpha, 0.f);

	}

	UFUNCTION()
	void SetNewLeverRotationTarget(float Rotation)
	{
		LeverRotationTarget = Rotation;
	}

	void TeleportToOtherTimePeriod(bool InCurrentTime)
	{	
		PlayerUsingLever.ClearPointOfInterestByInstigator(this);
		SetActorLocation(ActorLocation + FVector(0.f, InCurrentTime ? 50000.f : -50000.f, 0.f));
		if (PlayerUsingLever.OtherPlayer.ActorLocation.X > -7200.f)
		{
			PlayerUsingLever.OtherPlayer.SetActorLocation(PlayerUsingLever.OtherPlayer.ActorLocation + FVector(0.f, InCurrentTime ? 50000.f : -50000.f, 0.f));
		}
	}

	UFUNCTION()
	void LeverActivated(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		Player.AddCapability(n"RotatingLeverCapability");
		Player.SetCapabilityAttributeObject(n"RotatingLever", this);
		InteractionComp.Disable(n"IsInteractedWith");
		PlayerUsingLever = Player;
		PlayerStartedInteracting.Broadcast(Player);
	}

	UFUNCTION()
	void LeverDeActivated()
	{
		PlayerLeft.Broadcast(PlayerUsingLever);
		PlayerUsingLever.ClearPointOfInterestByInstigator(this);
		PlayerUsingLever = nullptr;
		InteractionComp.Enable(n"IsInteractedWith");
	}

	UFUNCTION()
	void LeftStickInput(FVector InputVector)
	{	
		if (PlayerUsingLever == nullptr)
			return;



		RotationMultiplier = InputVector.DotProduct(LeverMesh.ForwardVector) * -1.f;
	}

}