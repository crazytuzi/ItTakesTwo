import Cake.LevelSpecific.PlayRoom.GoldBerg.MarbleBall.MarbleBall;
import Cake.LevelSpecific.PlayRoom.GoldBerg.MarbleTags;
import Cake.LevelSpecific.PlayRoom.GoldBerg.SlackLineBalanceBoard;
import Peanuts.Audio.AudioStatics;

class UMarbleLockedOnBalanceboardCapability : UHazeCapability
{
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AMarbleBall Marble;
	USceneComponent LockInPlaceComponent;
	bool HasInterpolatedIntoPosition = false;

	FVector CurrentVelocity;
	FVector LastTickLocation;
	float TimeSinceStart;

	bool IsMovingIntoCenterPosition = true;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Marble = Cast<AMarbleBall>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (GetAttributeObject(FMarbleTags::LockedOnBalanceboardComponent) != nullptr)
        {
            return EHazeNetworkActivation::ActivateFromControl;
        }
        else
        {
            return EHazeNetworkActivation::DontActivate;
        }   
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{
		Params.AddObject(n"LockInPlaceComponent", GetAttributeObject(FMarbleTags::LockedOnBalanceboardComponent));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentVelocity = Marble.Mesh.GetPhysicsLinearVelocity();
		Marble.SetMarblePhysicsVelocity(CurrentVelocity);
		Marble.BlockCapabilities(FMarbleTags::MarblePhysics, this);
		Marble.BlockCapabilities(FMarbleTags::MarbleNetworkSync, this);
		HasInterpolatedIntoPosition = false;
		Marble.Mesh.SetSimulatePhysics(false);

		LockInPlaceComponent = Cast<USceneComponent>(ActivationParams.GetObject(n"LockInPlaceComponent"));

		Marble.AttachToComponent(LockInPlaceComponent, n"", EAttachmentRule::KeepWorld);
		//IsMovingIntoCenterPosition = true;

		FVector DirToBalanceBoardCenterlocation = LockInPlaceComponent.WorldLocation - Marble.ActorLocation;
		CurrentVelocity = CurrentVelocity.ProjectOnTo(DirToBalanceBoardCenterlocation);
		Marble.bCanSetVeloRtpc = false;
		Marble.bCanPlayHitEvent = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Marble.DetachFromActor();
		Marble.UnblockCapabilities(FMarbleTags::MarblePhysics, this);
		Marble.UnblockCapabilities(FMarbleTags::MarbleNetworkSync, this);
		Marble.Mesh.SetSimulatePhysics(true);
		Marble.bCanSetVeloRtpc = true;
		Marble.bCanPlayHitEvent = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (GetAttributeObject(FMarbleTags::LockedOnBalanceboardComponent) == nullptr)
        {
            return EHazeNetworkDeactivation::DeactivateFromControl;
        }
        else
        {
            return EHazeNetworkDeactivation::DontDeactivate;
        }
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if (IsMovingIntoCenterPosition)
		{
			SlowDownUntilReachedMiddlePosition(DeltaTime);
		}

		else
		{
			UpdateLocation(DeltaTime);
		}

		Marble.SetMarblePhysicsVelocity(CurrentVelocity);

	}

	void SlowDownUntilReachedMiddlePosition(float Deltatime)
	{
		float DistanceToCenterposition = LockInPlaceComponent.WorldLocation.Distance(Marble.ActorLocation);
		FVector DirToTarget = LockInPlaceComponent.WorldLocation - Marble.ActorLocation;
		TimeSinceStart += Deltatime;

		if (DirToTarget.DotProduct(CurrentVelocity) < 0)
		{
			IsMovingIntoCenterPosition = false;
			return;
		}

		if (CurrentVelocity.IsNearlyZero(0.01f))
		{
			IsMovingIntoCenterPosition = false;
			return;
		}

		if (DistanceToCenterposition < 10)
		{
			IsMovingIntoCenterPosition = false;
			return;
		}
		CurrentVelocity = CurrentVelocity - (CurrentVelocity * Deltatime * 0.6f);
		FVector HorizontalVelocity = CurrentVelocity;
		HorizontalVelocity.Y = 0.f;
		const float NormalizedVelo = HazeAudio::NormalizeRTPC01(HorizontalVelocity.Size(), 0.f, 500.f);
		Marble.HazeAkComponent.SetRTPCValue(HazeAudio::RTPC::MarbleBallVelocity, NormalizedVelo);
		PrintToScreen(""+NormalizedVelo);

		float Delta = CurrentVelocity.Size();
		
		// This is the rotation code!
		FRotator Rotation = Marble.Mesh.GetWorldRotation();
		FVector RotateAxis = -CurrentVelocity.CrossProduct(FVector::UpVector);
		//FVector RotateAxis = FVector::RightVector;
		RotateAxis.Normalize();
		const float MarbleRadius = 22.f;
		FQuat DeltaRotation = FQuat(RotateAxis, (Delta * Deltatime) / 22.f);
		Rotation = Rotation.Compose(DeltaRotation.Rotator());
		Marble.Mesh.SetWorldRotation(Rotation);
		// End rotation code!

		FVector Location = Marble.ActorLocation + CurrentVelocity * Deltatime;
		Marble.SetActorLocation(Location);
	}

	void UpdateLocation(float DeltaTime)
	{
		FVector Newposition = FVector::ZeroVector;
		Newposition = FMath::Lerp(Owner.ActorLocation, LockInPlaceComponent.GetWorldLocation(), DeltaTime * 2.f);
		float Delta = LastTickLocation.Distance(LockInPlaceComponent.GetWorldLocation());
		
		// This is the rotation code!
		ASlackLineBalanceBoard BalanceBoard = Cast<ASlackLineBalanceBoard>(LockInPlaceComponent.Owner);

		FRotator Rotation = Marble.ActorRotation;
		FVector RotateAxis = FVector::RightVector;
		RotateAxis.Normalize();
		const float MarbleRadius = 22.f;
		FQuat DeltaRotation = FQuat(RotateAxis, (BalanceBoard.BallVelocity) / 22.f);
		Rotation = Rotation.Compose(DeltaRotation.Rotator());
		Marble.SetActorRotation(Rotation);
		// End rotation code!

		const float	RotationVelo = FMath::Abs(BalanceBoard.BallVelocity);
		const float NormalizedVelo = HazeAudio::NormalizeRTPC01(RotationVelo, 0.f, 5.f);
		Marble.HazeAkComponent.SetRTPCValue(HazeAudio::RTPC::MarbleBallVelocity, NormalizedVelo);	

		LastTickLocation = Newposition;
		Marble.SetActorLocation(Newposition);

		if (LockInPlaceComponent.WorldLocation.Distance(Marble.ActorLocation) < 1)
		{
			HasInterpolatedIntoPosition = true;
		}
	}
}