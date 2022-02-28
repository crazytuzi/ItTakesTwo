import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Train.CourtyardTrainCarriage;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Train.CourtyardTrainTrack;
import Vino.Interactions.InteractionComponent;
import Vino.Tutorial.TutorialStatics;
import Vino.Camera.Components.CameraMatchDirectionComponent;
import Vino.Camera.Components.CameraSpringArmComponent;
import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Camera.Actors.Volumes.SpringArmCameraVolume;
import Cake.LevelSpecific.PlayRoom.VOBanks.CastleCourtyardVOBank;
import Vino.Triggers.PlayerLookAtTriggerComponent;
import Peanuts.Foghorn.FoghornStatics;
import Vino.Collision.LazyPlayerOverlapManagerComponent;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureTrainRide;

event void FChimneyPulse();
event void FTrainStoppedAtStation();
event void FTrainLeavingStation();

class ACourtyardTrain : AHazeActor
{
	UPROPERTY()
	FTrainStoppedAtStation OnStoppedAtStation;
	UPROPERTY()
	FTrainLeavingStation OnLeavingStation;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USceneComponent WhistleSkeletalRoot;

	UPROPERTY(DefaultComponent, Attach = WhistleSkeletalRoot)
	UStaticMeshComponent WhistleHandle;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UStaticMeshComponent SmallWheelsFront;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UStaticMeshComponent SmallWheelsBack;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UStaticMeshComponent LargeWheelsFront;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UStaticMeshComponent LargeWheelsBack;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USceneComponent ConnectingRodFrontPivot;

	UPROPERTY(DefaultComponent, Attach = ConnectingRodFrontPivot)
	UStaticMeshComponent ConnectingRodFrontLeft;

	UPROPERTY(DefaultComponent, Attach = ConnectingRodFrontPivot)
	UStaticMeshComponent ConnectingRodFrontRight;

	UPROPERTY(DefaultComponent, Attach = LargeWheelsFront)
	USceneComponent ConnectingRodPivot;

	UPROPERTY(DefaultComponent, Attach = ConnectingRodPivot)
	UStaticMeshComponent ConnectingRodLeft;

	UPROPERTY(DefaultComponent, Attach = ConnectingRodPivot)
	UStaticMeshComponent ConnectingRodRight;

	UPROPERTY()
	UCastleCourtyardVOBank VOBank;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USceneComponent RearHook;

	UPROPERTY(DefaultComponent)
	UHazeSplineFollowComponent FollowComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UInteractionComponent InteractionComp;
	default InteractionComp.bUseLazyTriggerShapes = true;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UCameraMatchDirectionComponent MatchDirectionComponent;

   	UPROPERTY(DefaultComponent, Attach = MatchDirectionComponent)
	UCameraSpringArmComponent SpringArm;

	UPROPERTY(DefaultComponent, Attach = SpringArm, ShowOnActor)
	UHazeCameraComponent Camera;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent ChimneyNiagaraComp;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent WhistleNiagaraComp;

	UPROPERTY(DefaultComponent)
	UBoxComponent PlayerKillBox;

	UPROPERTY(DefaultComponent)
	ULazyPlayerOverlapManagerComponent OverlapComp;
	default OverlapComp.ActorResponsiveDistance = 4000.f;

	UPROPERTY()
	FChimneyPulse OnChimneyPulse;

	UPROPERTY()
	TSubclassOf<UHazeCapability> AudioCapabilityClass;

	default bRunConstructionScriptOnDrag = true;

	UPROPERTY(NotEditable)
	float DistanceAlongSpline;	

	UPROPERTY(Category = Settings)
	UHazeCapabilitySheet PlayerSheet;
	UPROPERTY(Category = Settings)
	TPerPlayer<ULocomotionFeatureTrainRide> PlayerFeatures;
	UPROPERTY(Category = Settings)
	ACourtyardTrainTrack Track;
	UPROPERTY(Category = Settings)
	TArray<ACourtyardTrainCarriage> Carriages;

	UPROPERTY(Category = Settings|Wheels)
	float Wheelbase = 230.f;
	UPROPERTY(Category = Settings|Wheels)
	float SmallWheelRadius = 30.f;
	UPROPERTY(Category = Settings|Wheels)
	float LargeWheelRadius = 55.0f;

	float CurrentSpeed = 500.f;
	float Angle = 0.f;

	TPerPlayer<bool> bRideBarkPlayed;

	TPerPlayer<bool> bKillVolumeOverlappingPlayers;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (Track == nullptr)
			return;

		DistanceAlongSpline = Track.Spline.GetDistanceAlongSplineAtWorldLocation(ActorLocation);
		FHazeSplineSystemPosition Position;
		Position.FromData(Track.Spline, DistanceAlongSpline, true);

		FTransform TrainTransform = GetTrainTransform(Position);
		SetActorTransform(TrainTransform);

		// Update any carraiges following the train		
		for (int Index = 0; Index < Carriages.Num(); Index++)
		{
			ACourtyardTrainCarriage Carriage;
			FTransform Transform;
			if (GetCarriageTransfromAtIndex(Index, Carriage, Transform))
			{
				Carriage.SetActorTransform(Transform);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnActivated.AddUFunction(this, n"OnInteractionActivated");

		if (PlayerSheet != nullptr)
			Capability::AddPlayerCapabilitySheetRequest(PlayerSheet);
			//Player.SetCapabilityAttributeObject(n"Train", this);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.SetCapabilityAttributeObject(n"Train", this);

		for (ACourtyardTrainCarriage Carriage : Carriages)
		{
			Carriage.OnCarriageRidden.AddUFunction(this, n"PlayTrainRiddenBark");
			Carriage.Track = Track;
			Carriage.TrainCrumbComp = CrumbComp;
		}

		PlayerKillBox.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		PlayerKillBox.OnComponentEndOverlap.AddUFunction(this, n"OnComponentEndOverlap");

		UClass AudioClass = AudioCapabilityClass.Get();
		if(AudioClass != nullptr)
			AddCapability(AudioClass);

		OverlapComp.MakeOverlapsLazy(PlayerKillBox);
	}
	
	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		if (PlayerSheet != nullptr)
			Capability::RemovePlayerCapabilitySheetRequest(PlayerSheet);
	}	

	UFUNCTION(NotBlueprintCallable)
	private void OnInteractionActivated(UInteractionComponent UsedInteraction, AHazePlayerCharacter Player)
	{
		Player.SetCapabilityAttributeObject(n"Train", this);
		Player.SetCapabilityAttributeObject(n"TrainInteraction", UsedInteraction);
		SetCapabilityActionState(n"AudioStartedTrainInteraction", EHazeActionState::ActiveForOneFrame);

		UsedInteraction.Disable(n"InUse");		

		Online::UnlockAchievement(Player, n"RideTrain");		
		
		//Player.ActivateCamera(Camera, 1.5f, this);
	}

	void CancelTrainInteraction(AHazePlayerCharacter Player, UInteractionComponent UsedInteraction)
	{
		SetCapabilityActionState(n"AudioCanceledTrainInteraction", EHazeActionState::ActiveForOneFrame);

		UsedInteraction.Enable(n"InUse");

		//Player.DeactivateCameraByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!bKillVolumeOverlappingPlayers[Player])
				continue;
			if (CurrentSpeed < 100.f)
				continue;
			
			bKillVolumeOverlappingPlayers[Player] = false;

			SetCapabilityActionState(n"AudioTrainHitPlayer", EHazeActionState::ActiveForOneFrame);
			KillPlayer(Player);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
		UPrimitiveComponent OtherComponent, int OtherBodyIndex,
		bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		bKillVolumeOverlappingPlayers[Player] = true;
	}

	UFUNCTION(NotBlueprintCallable)
    void OnComponentEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		bKillVolumeOverlappingPlayers[Player] = false;
	}

	FTransform GetTrainTransform(FHazeSplineSystemPosition Position)
	{
		// Update train location
		FHazeSplineSystemPosition FrontAxle = Position;
		FrontAxle.Move(Wheelbase * 0.5f);

		FHazeSplineSystemPosition RearAxle = Position;
		RearAxle.Move(-Wheelbase * 0.5f);

		FVector FrontAxleLocation = FrontAxle.GetWorldLocation();
		FVector RearAxleLocation = RearAxle.GetWorldLocation();
		FVector TrainLocation = (FrontAxleLocation + RearAxleLocation) / 2.f;

		FQuat FrontAxleRotation = FrontAxle.GetWorldRotation().Quaternion();
		FQuat RearAxleRotation = RearAxle.GetWorldRotation().Quaternion();
		FQuat TrainRotation = FQuat::Slerp(FrontAxleRotation, RearAxleRotation, 0.5f);

		FTransform TrainTransform;
		TrainTransform.Location = TrainLocation;
		TrainTransform.Rotation = TrainRotation;

		return TrainTransform;
	}

	bool GetCarriageTransfromAtIndex(int Index, ACourtyardTrainCarriage& Carriage, FTransform& Transform)
	{
		if (Track == nullptr)
			return false;

		Carriage = Carriages[Index];
		if (Carriage == nullptr)
			return false;

		FHazeSplineSystemPosition CarriagePosition;
		if (FollowComp.HasActiveSpline())
			CarriagePosition = FollowComp.Position;
		else
			CarriagePosition.FromData(Track.Spline, DistanceAlongSpline, true);

		float CarriageDistanceBehindTrain = FMath::Abs(RearHook.RelativeLocation.Y);
		const float GapBetweenCarraiges = 37.5f;
		for (int i = 0; i <= Index; i++)
		{
			if (i != 0)
				CarriageDistanceBehindTrain += FMath::Abs(Carriages[i - 1].RearHook.RelativeLocation.Y);

			CarriageDistanceBehindTrain += FMath::Abs(Carriages[i].FrontHook.RelativeLocation.Y);
			CarriageDistanceBehindTrain += GapBetweenCarraiges;
		}
		CarriagePosition.Move(-CarriageDistanceBehindTrain);

		FHazeSplineSystemPosition FrontAxle = CarriagePosition;
		FrontAxle.Move(Carriage.Wheelbase * 0.5f);

		FHazeSplineSystemPosition RearAxle = CarriagePosition;
		RearAxle.Move(-Carriage.Wheelbase * 0.5f);

		FVector FrontAxleLocation = FrontAxle.GetWorldLocation();
		FVector RearAxleLocation = RearAxle.GetWorldLocation();
		FVector CarriageLocation = (FrontAxleLocation + RearAxleLocation) / 2.f;

		FQuat FrontAxleRotation = FrontAxle.GetWorldRotation().Quaternion();
		FQuat RearAxleRotation = RearAxle.GetWorldRotation().Quaternion();
		FQuat CarriageRotation = FQuat::Slerp(FrontAxleRotation, RearAxleRotation, 0.5f);

		FTransform CarriageTransform;
		CarriageTransform.Location = CarriageLocation;
		CarriageTransform.Rotation = CarriageRotation;

		Transform = CarriageTransform;
		return true;
	}

	float GetCorrectedDistanceAlongSpline(float DistanceAlongSpline)
	{
		if (DistanceAlongSpline > Track.Spline.GetSplineLength())
			return DistanceAlongSpline % Track.Spline.GetSplineLength();
		else if (DistanceAlongSpline < 0.f)
			return (DistanceAlongSpline % -Track.Spline.GetSplineLength()) + Track.Spline.GetSplineLength();

		return DistanceAlongSpline;
	}

	UFUNCTION()
	void PlayTrainRiddenBark(AHazePlayerCharacter Player)
	{
		if (bRideBarkPlayed[Player])
			return;

		bRideBarkPlayed[Player] = true;

		FName EventName = Player.IsMay() ? n"FoghornDBPlayroomCastleTrainRideMay" : n"FoghornDBPlayroomCastleTrainRideCody";
		PlayFoghornVOBankEvent(VOBank, EventName);
	}
}