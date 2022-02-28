import Cake.SlotCar.SlotCarActor;
import Cake.SlotCar.SlotCarSettings;
import Cake.SlotCar.SlotCarTrackActor;

class USlotCarDeslotCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SlotCar");
	default CapabilityTags.Add(n"SlotCarMovement");
	default CapabilityTags.Add(n"SlotCarDeslot");

	default CapabilityDebugCategory = n"SlotCar";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 110;

	ASlotCarActor SlotCar;
	ASlotCarTrackActor SlotCarTrack;
	FVector MeshRelativeLocation;

	bool bEffectDeactivated = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SlotCar = Cast<ASlotCarActor>(Owner);
		SlotCarTrack = Cast<ASlotCarTrackActor>(SlotCar.TrackActor);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (FMath::Abs(SlotCar.AcceleratedYaw.Value) <= SlotCarSettings::Slide.AngleMax)
			return EHazeNetworkActivation::DontActivate;			

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ActiveDuration < SlotCarSettings::Deslot.RespawnTime)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SlotCar.BlockCapabilities(n"SlotCar", this);

		SlotCar.AcceleratedYaw.SnapTo(0.f);

		MeshRelativeLocation = SlotCar.CarBody.RelativeLocation;
        SlotCar.CarBody.SetSimulatePhysics(true);
        SlotCar.CarBodyPivot.SetRelativeRotation(FRotator::ZeroRotator);

		bEffectDeactivated = false;

		SlotCar.CurrentSpeed = 0.f;

		SlotCarTrack.MinigameComp.PlayFailGenericVOBark(SlotCar.OwningPlayer);

		if (SlotCar.DeslotForceFeedbackEffect != nullptr)
			SlotCar.OwningPlayer.PlayForceFeedback(SlotCar.DeslotForceFeedbackEffect, false, true, NAME_None, 1.f);

		if (SlotCar.OffTrackEvent != nullptr)
			SlotCar.HazeAkComp.HazePostEvent(SlotCar.OffTrackEvent);
			SlotCar.HazeAkComp.HazePostEvent(SlotCar.StopMovingEvent);
			//UHazeAkComponent::HazePostEventFireForget(SlotCar.OffTrackEvent, FTransform());
			SlotCar.HazeAkComp.SetRTPCValue("Rtpc_World_Shared_SideContent_SlotCars_SkidAmount", 0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bEffectDeactivated && ActiveDuration > (SlotCarSettings::Deslot.RespawnTime * 0.75f))
		{
			bEffectDeactivated = true;
			SlotCar.TrailNiagaraComp.Deactivate();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SlotCar.CarBody.SetSimulatePhysics(false);
		SlotCar.CarBody.AttachToComponent(SlotCar.CarBodyPivot);
		SlotCar.CarBody.SetRelativeLocation(MeshRelativeLocation);

		SlotCar.TrailNiagaraComp.Activate();
		SlotCar.RespawnNiagaraComp.Activate();
		SlotCar.HazeAkComp.HazePostEvent(SlotCar.RespawnEvent);

		SlotCar.UnblockCapabilities(n"SlotCar", this);
	}
}