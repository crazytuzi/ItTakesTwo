import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Cake.LevelSpecific.Basement.ParentBlob.ButtonHold.ParentBlobButtonHoldComponent;
import Cake.LevelSpecific.Basement.ParentBlob.ButtonHold.ParentBlobButtonHoldPlayerCapability;
import Cake.LevelSpecific.Basement.ParentBlob.Kinetic.ParentBlobKineticBase;
import Cake.LevelSpecific.Basement.ParentBlob.Shooting.ParentBlobShootingComponent;

class UParentBlobAmmoPlayerShootCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"KineticTargeting");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UParentBlobShootingComponent ShootingComponent;
	UHazeSkeletalMeshComponentBase Mesh;
	AParentBlobShootingProjectile ActiveProjectile;
	AParentBlobAmmoContainerActor AmmoContainer;
	UParentBlobPlayerComponent ParentBlobComponent;
	UParentBlobKineticComponent KineticComponent;
	AParentBlob ParentBlob;

	bool bAwaytingProjectileResponse = false;
	FQuat CurrentOffsetRotation;
	FRotator LastDeltaRotation;
	bool bHasGrabbedProjectile = false;
	float GrabbedAttachmentOffset = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ParentBlobComponent = UParentBlobPlayerComponent::Get(Player);
		ParentBlob = ParentBlobComponent.ParentBlob;
		ShootingComponent = UParentBlobShootingComponent::Get(ParentBlob);
		Mesh = UHazeSkeletalMeshComponentBase::Get(ParentBlob);
		KineticComponent = UParentBlobKineticComponent::Get(ParentBlob);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		const FParentBlobKineticPlayerInputData& PlayerData = KineticComponent.PlayerInputData[int(Player.Player)];
		if(PlayerData.TargetedInteraction == nullptr)
			return EHazeNetworkActivation::DontActivate;

		auto AmmoInteraction = Cast<AParentBlobAmmoContainerActor>(PlayerData.TargetedInteraction.Owner);
		if(AmmoInteraction == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!PlayerData.bIsHolding)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bAwaytingProjectileResponse)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(AmmoContainer == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		const FParentBlobKineticPlayerInputData& PlayerData = KineticComponent.PlayerInputData[int(Player.Player)];
		if(!PlayerData.bIsHolding)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FParentBlobKineticPlayerInputData& PlayerData = KineticComponent.PlayerInputData[Player.Player];
		AmmoContainer = Cast<AParentBlobAmmoContainerActor>(PlayerData.TargetedInteraction.Owner);

		SetMutuallyExclusive(n"KineticTargeting", true);
		ParentBlob.BlockCapabilities(n"KineticTargeting", this);
		
		auto Visualizer = KineticComponent.GetKineticVisualizer(Player);
		Visualizer.SetStatus(EKineticInputVisualizerStatus::ActiveWithTargetAndInput);
		
		CurrentOffsetRotation = FQuat::Identity;
		//PlayerData.TargetedInteraction = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(n"KineticTargeting", false);
		ParentBlob.UnblockCapabilities(n"KineticTargeting", this);
		auto Visualizer = KineticComponent.GetKineticVisualizer(Player);
		Visualizer.AttachRootComponentToActor(ParentBlob, NAME_None, EAttachLocation::SnapToTarget);
		Visualizer.SetStatus(EKineticInputVisualizerStatus::Inactive);
		if(ActiveProjectile != nullptr)
		{
			if(AmmoContainer.Launch(ActiveProjectile, Player, ParentBlob))
			{
				FParentBlobShootingDelegateData Data;
				Data.Player = Player;
				Data.Projectile = ActiveProjectile;
				ShootingComponent.OnShootProjectile.Broadcast(Data);
				
				// Animation
				if(Player.IsMay())
					ParentBlob.SetAnimBoolParam(n"MayPerfomedValidShot", true);
				else
					ParentBlob.SetAnimBoolParam(n"CodyPerfomedValidShot", true);
			}
			else
			{
				// Animation
				if(Player.IsMay())
					ParentBlob.SetAnimBoolParam(n"MayPerfomedInvalidShot", true);
				else
					ParentBlob.SetAnimBoolParam(n"CodyPerfomedInvalidShot", true);
			}

			ActiveProjectile = nullptr;
		}

		GrabbedAttachmentOffset = 0.f;
		bHasGrabbedProjectile = false;

		if(Player.IsMay())
			ShootingComponent.bMayIsInteractingWithProjetile = false;
		else
			ShootingComponent.bCodyIsInteractingWithProjetile = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// We are waiting for the network validation
		FParentBlobKineticPlayerInputData& PlayerData = KineticComponent.PlayerInputData[int(Player.Player)];
		if(!bAwaytingProjectileResponse)
		{
			// Create the projectile if needed
			if(AmmoContainer != nullptr && ActiveProjectile == nullptr)
			{
				bAwaytingProjectileResponse = false;
				AmmoContainer.TakeProjectile(Player, this, n"OnProjectileSpawned");
			}
			
			UParentBlobProjetileAttachmentData AttachmentData = Player.IsMay() ? ShootingComponent.LeftAttachment : ShootingComponent.RightAttachment;
			if(!AttachmentData.DeltaRotation.IsNearlyZero() && LastDeltaRotation.Equals(AttachmentData.DeltaRotation))
			{
				CurrentOffsetRotation *= FQuat(AttachmentData.DeltaRotation * DeltaTime);
			}
			else
			{
				LastDeltaRotation = AttachmentData.DeltaRotation;
				CurrentOffsetRotation = FQuat::Identity;
			}

			// Lerp the projectile toward the correct hand
			if(ActiveProjectile != nullptr)
			{
				ActiveProjectile.ChargeUp(DeltaTime);

				// Calculate the offset transform
				if(!ActiveProjectile.IsFullyCharged())
				{
					float TransformAlpha = ActiveProjectile.GetChargeAlpha();
					TransformAlpha = FMath::EaseInOut(0.f, 1.f, TransformAlpha, 2.f);
			
					FVector ContainerLocation = AmmoContainer.AmmoLerpFrom.GetWorldLocation();
					FVector WantedLocation = FMath::Lerp(ContainerLocation, GetAttachmentTransform(AttachmentData).Location, TransformAlpha);

					ActiveProjectile.SetActorLocation(WantedLocation);
				}
				else
				{
					
					FTransform AttachmentTransform = GetAttachmentTransform(AttachmentData);

					// Calculate the rotation offset
					FVector RotationOffset = FVector(GrabbedAttachmentOffset, 0.f, 0.f);
					RotationOffset = CurrentOffsetRotation.RotateVector(RotationOffset);
					RotationOffset = AttachmentTransform.TransformVector(RotationOffset);

					AttachmentTransform.AddToTranslation(RotationOffset);
					ActiveProjectile.SetActorLocation(AttachmentTransform.Location);

					if(!bHasGrabbedProjectile)
					{
						bHasGrabbedProjectile = true;
						// Animation
						if(Player.IsMay())
							ParentBlob.SetAnimBoolParam(n"MayGrabbedProjectile", true);
						else
							ParentBlob.SetAnimBoolParam(n"CodyGrabbedProjectile", true);
					}
					else
					{
						GrabbedAttachmentOffset = FMath::FInterpTo(GrabbedAttachmentOffset, AttachmentData.RotationOffset, DeltaTime, 2.f);
					}
				}
			}
		}
	}

	FTransform GetAttachmentTransform(UParentBlobProjetileAttachmentData AttachmentData) const
	{
		FTransform Transform = ParentBlob.GetActorTransform();
		if(AttachmentData.BoneName != NAME_None)
			Transform.SetLocation(Mesh.GetSocketLocation(AttachmentData.BoneName));

		Transform.AddToTranslation(Transform.TransformVector(AttachmentData.Offset));
		return Transform;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnProjectileSpawned(AParentBlobShootingProjectile SpawnedProjectile)
	{
		bAwaytingProjectileResponse = false;
		ActiveProjectile = SpawnedProjectile;
		auto Visualizer = KineticComponent.GetKineticVisualizer(Player);
		Visualizer.AttachRootComponentToActor(ActiveProjectile, NAME_None, EAttachLocation::SnapToTarget);

		if(Player.IsMay())
			ShootingComponent.bMayIsInteractingWithProjetile = true;
		else
			ShootingComponent.bCodyIsInteractingWithProjetile = true;
	}
}