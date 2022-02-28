import Cake.LevelSpecific.Garden.Vine.VineComponent;
import Vino.Camera.Capabilities.CameraTags;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;

class UVineWhipCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"Vine");
	default CapabilityTags.Add(n"VineActive");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 51;

	AHazePlayerCharacter Player;
	UVineComponent VineComp;
	UHazeMovementComponent MoveComp;

	bool bHasActivateVine = false;
	UVineImpactComponent ImpactPoint;
	FVineHitResult ReplicatedImpact;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		VineComp = UVineComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::WeaponFire))
        	return EHazeNetworkActivation::DontActivate;

		if(!VineComp.bCanActivateVine)
			return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!bHasActivateVine)
		 	return EHazeNetworkDeactivation::DontDeactivate;

		if(VineComp.VineActiveType != EVineActiveType::Inactive)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		FVineHitResult VineHit;
		VineComp.GetVineImpact(VineHit);
		ActivationParams.AddStruct(n"Impact", VineHit);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{		
		SetMutuallyExclusive(n"VineActive", true);
		Player.BlockCapabilities(MovementSystemTags::TurnAround, this);

		ActivationParams.GetStruct(n"Impact", ReplicatedImpact);
		VineComp.UpdateVineHitResultFromReplication(ReplicatedImpact);

		ImpactPoint = VineComp.GetValidVineImpactComponent();
		if(ImpactPoint != nullptr)
		{
			Player.ActivatePoint(ImpactPoint, this);	
		}
	
		VineComp.LockAttachmentPoint();
		bHasActivateVine = false;
		VineComp.VineActiveType = EVineActiveType::PreExtending;
		Player.SetCapabilityActionState(n"AudioVineThrow", EHazeActionState::ActiveForOneFrame);

		VineComp.SetVineAnimationType(EVineActiveType::PreExtending);
		Player.Mesh.HideBoneByName(n"BigLeaf1", EPhysBodyOp::PBO_None);	

		VineComp.SetVisibility(true);
		Niagara::SpawnSystemAttached(VineComp.SpawnEffect, Player.Mesh, VineComp.AttachPoint, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);

		FHazeCameraBlendSettings CamBlend;
		CamBlend.BlendTime = 0.f;
		CamBlend.Fraction = 1.f;
		Player.ApplyCameraSettings(VineComp.ActiveVineCameraSettings, CamBlend, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(n"VineActive", false);
		Player.UnblockCapabilities(MovementSystemTags::TurnAround, this);

		FHazeQueriedActivationPoint ActiveQuery;
		if(Player.GetActivePoint(UVineImpactComponent::StaticClass(), ActiveQuery))
		{
			Player.UpdateActivationPointWidget(ActiveQuery);
			VineComp.CurrentWidget.MakeAutoAim(ActiveQuery.Transform.Location);
		}

		Player.ClearCameraSettingsByInstigator(this, 0.5f);
		Player.DeactivateCurrentPoint(this);
		VineComp.ReleaseAttachmentPoint();
		ImpactPoint = nullptr;
		VineComp.SetVisibility(false);
		VineComp.VineActor.DeactivateVine();
		VineComp.ClearVineValues();
		VineComp.SetVineAnimationType(EVineActiveType::Inactive);
		Player.Mesh.UnHideBoneByName(n"BigLeaf1");
		VineComp.CurrentActiveTime = 0;
		ReplicatedImpact = FVineHitResult();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		MoveComp.SetAnimationToBeRequested(n"VineMovement");

		// Update the widget for the current point
		FHazeQueriedActivationPoint ActiveQuery;
		if(Player.GetActivePoint(UVineImpactComponent::StaticClass(), ActiveQuery))
		{
			Player.UpdateActivationPointWidget(ActiveQuery);
			VineComp.CurrentWidget.MakeAutoAim(ActiveQuery.Transform.Location);
		}

		if(!bHasActivateVine && VineComp.CurrentActiveTime >= VineComp.VineActivationDelayTime)
		{
			bHasActivateVine = true;
			VineComp.VineActor.ActivateVineWhip(Owner.GetActorRotation());
			VineComp.SetVineAnimationType(EVineActiveType::Extending);
		}

		if(VineComp.VineActiveType == EVineActiveType::Extending)
		{
			if(!VineComp.UpdateExtending(DeltaTime))
			{
				if(ReplicatedImpact.bBlockingHit)
				{
					Niagara::SpawnSystemAtLocation(VineComp.VineActor.WhipImpactEffect, VineComp.GetTargetPoint());
					if(ReplicatedImpact.ImpactComponent != nullptr && ReplicatedImpact.ImpactComponent.WhippedForceFeedback != nullptr)
						Player.PlayForceFeedback(ReplicatedImpact.ImpactComponent.WhippedForceFeedback, false, true, n"VineHit");
					else
					{
						Player.PlayForceFeedback(VineComp.WhipForceFeedback, false, true, n"VineHit");
						Player.SetCapabilityActionState(n"AudioVineCrack", EHazeActionState::ActiveForOneFrame);
					}

					Player.PlayCameraShake(VineComp.WhipCamShake, 4.5f);
				}

				// Broadcast the impact
				if(ReplicatedImpact.ImpactComponent != nullptr)
				{
					ReplicatedImpact.ImpactComponent.VineHit();
				}

				VineComp.OnStartRetractingEvent.Broadcast(ReplicatedImpact);

				VineComp.StartRetracting(nullptr);
				Player.SetCapabilityActionState(n"AudioVineCatch", EHazeActionState::ActiveForOneFrame);
			}
		}
		else if(VineComp.VineActiveType == EVineActiveType::Retracting)
		{
			if(!VineComp.UpdateRetracting(DeltaTime))
			{
				// We have reached the target
				VineComp.SetVineAnimationType(EVineActiveType::Inactive);
			}
		}

		VineComp.CurrentActiveTime += DeltaTime;
	}
}