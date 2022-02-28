import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CourtyardCraneWreckingBall;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CastleWreckingDoor;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CastleCourtyardDestroyableActor;

class UCourtyardWreckingBallHitCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 25;

	ACourtyardCraneWreckingBall WreckingBall;
	UHazeCrumbComponent CrumbComp;

	ACastleWreckingDoor HitWreckingDoor;
	ACastleCourtyardDestroyableActor HitDestroyableActor;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		WreckingBall = Cast<ACourtyardCraneWreckingBall>(Owner);
		CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);

		if (HasControl())
			WreckingBall.CollisionTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnCollisionOverlap");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (HitWreckingDoor != nullptr)
        	return EHazeNetworkActivation::ActivateUsingCrumb;

		if (HitDestroyableActor != nullptr)
        	return EHazeNetworkActivation::ActivateUsingCrumb;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		if (HitWreckingDoor != nullptr)
			OutParams.AddObject(n"HitObject", HitWreckingDoor);
		else if (HitDestroyableActor != nullptr)
			OutParams.AddObject(n"HitObject", HitDestroyableActor);

		if (HitWreckingDoor != nullptr)
		{
			float AngularSpeed = WreckingBall.AngularVelocity.Size();
			if (AngularSpeed >= 0.4f)
			{
				WreckingBall.DoorHits += 1;

				if (WreckingBall.DoorHits == 2 && WreckingBall.VOBank != nullptr)
					PlayFoghornVOBankEvent(WreckingBall.VOBank, n"FoghornDBPlayroomCastleCourtyardWreckingBallFinal");
			}
			if (AngularSpeed >= 0.7f || WreckingBall.DoorHits >= 3)
				OutParams.AddActionState(n"BreakDoor");
			

			// PrintScaled("DoorHits: " + WreckingBall.DoorHits);
			// PrintScaled("AngularSpeed: " + AngularSpeed + " [0.4/0.7]");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UObject HitObject = ActivationParams.GetObject(n"HitObject");

		HitWreckingDoor = Cast<ACastleWreckingDoor>(HitObject);
		HitDestroyableActor = Cast<ACastleCourtyardDestroyableActor>(HitObject);
		bool bShouldBreak = ActivationParams.GetActionState(n"BreakDoor");

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.SetAnimBoolParam(n"HitDoor", true);
		}

		if (!WreckingBall.bCutsceneStarted && HitWreckingDoor != nullptr)
		{
			float AngularSpeed = WreckingBall.AngularVelocity.Size();
			HitDoor(HitWreckingDoor, AngularSpeed);

			if (bShouldBreak)
				WreckingBall.BroadcastCutscene();

			return;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		HitWreckingDoor = nullptr;
		HitDestroyableActor = nullptr;
	}

	UFUNCTION()
	void OnCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{	
		HitWreckingDoor = Cast<ACastleWreckingDoor>(OtherActor);
		HitDestroyableActor = Cast<ACastleCourtyardDestroyableActor>(OtherActor);
	}

	void HitDoor(ACastleWreckingDoor WreckingDoor, float Scale)
	{
		WreckingDoor.HitByWreckingBall(Scale);

		WreckingBall.AngularVelocity = -WreckingBall.AngularVelocity;
		WreckingBall.AngularVelocity *= 0.75f;

		if (WreckingBall.HitDoorForceFeedback != nullptr)
		{
			for (AHazePlayerCharacter Player : Game::Players)
			{
				Player.PlayForceFeedback(WreckingBall.HitDoorForceFeedback, false, false, NAME_None, Scale * 1.4f);
				Player.PlayCameraShake(WreckingBall.HitDoorCameraShake, 0.75f);
			}
		}
	}
}