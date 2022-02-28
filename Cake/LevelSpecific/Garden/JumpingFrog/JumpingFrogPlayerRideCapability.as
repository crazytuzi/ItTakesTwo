import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrogTags;
import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrog;
import Peanuts.Outlines.Outlines;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrogPlayerRideComponent;
import Vino.Camera.Capabilities.CameraTags;
import Cake.LevelSpecific.Garden.Sickle.Player.Sickle;
import Cake.LevelSpecific.Garden.Sickle.SickleTags;
import Vino.Tutorial.TutorialStatics;

// Active when a player is riding the frog

class UJumpingFrogPlayerRideCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	AHazePlayerCharacter Player;
	UHazeCrumbComponent CrumbComp;
	UHazeMovementComponent MoveComp;
	UJumpingFrogPlayerRideComponent RideComponent;

	bool TutorialShown = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		RideComponent = UJumpingFrogPlayerRideComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(RideComponent.Frog == nullptr)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WasActionStarted(n"ForceQuitRiding"))
		 	return EHazeNetworkDeactivation::DeactivateLocal;

		if(RideComponent.Frog == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(RideComponent.Frog.bCharging)
			return EHazeNetworkDeactivation::DontDeactivate;

/* 		if (WasActionStarted(ActionNames::Cancel) && RideComponent.Frog.FrogMoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateFromControl; */

		if(IsActioning(n"Dismount") && RideComponent.Frog.FrogMoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.TriggerMovementTransition(this);
		Player.BlockMovementSyncronization(this);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(ActionNames::WeaponAim, this);
		Player.BlockCapabilities(GardenSickle::SickleAttack, this);
		Player.BlockCapabilities(n"Death", this);
		Player.Mesh.CastShadow = false;
		
		const FTransform MeshTransform = Player.Mesh.GetWorldTransform();
		Player.TriggerMovementTransition(this);
		Player.AddLocomotionFeature(RideComponent.MovementFeature);
		Player.RootComponent.AttachToComponent(RideComponent.Frog.RootComponent);
		RideComponent.Frog.Mesh.OnPostAnimEvalComplete.AddUFunction(this, n"OnFrogAnimationUpdate");

		Player.ApplyCameraSettings(RideComponent.Frog.FrogCamSettings, FHazeCameraBlendSettings(1.f), this);
		Player.DisableMovementComponent(this);

		RideComponent.Frog.Mesh.AddMeshToPlayerOutline(Player, this);
		RideComponent.Frog.SetControlSide(Owner);
		RideComponent.Frog.EnableMovementComponent(RideComponent.Frog);

/* 		if(!TutorialShown)
		{
			ShowTutorialPrompt(Player, RideComponent.Frog.JumpPrompt, this);
			ShowTutorialPrompt(Player, RideComponent.Frog.DashPrompt, this);
			TutorialShown = true;
		} */

		UHazeMovementComponent FrogMoveComp = UHazeMovementComponent::Get(RideComponent.Frog);
		if(FrogMoveComp != nullptr)
		{
			if(FrogMoveComp.DownHit.Actor != nullptr)
			{
				if(FrogMoveComp.DownHit.Actor.ActorHasTag(n"NotFrogRespawnable") || FrogMoveComp.DownHit.Component.HasTag(n"NotFrogRespawnable"))
					return;
			}
		}

		RideComponent.Frog.RespawnTransform = RideComponent.Frog.ActorTransform;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);

		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		Player.UnblockMovementSyncronization(this);
		
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(ActionNames::WeaponAim, this);
		Player.UnblockCapabilities(	GardenSickle::SickleAttack, this);
		Player.UnblockCapabilities(n"Death", this);
		Player.Mesh.CastShadow = true;
	
		Player.Mesh.SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);	
		Player.ClearCameraSettingsByInstigator(this);
		Player.RemoveLocomotionFeature(RideComponent.MovementFeature);
		Player.EnableMovementComponent(this);

		if(RideComponent.Frog != nullptr)
		{
			RideComponent.Frog.Mesh.OnPostAnimEvalComplete.UnbindObject(this);
			RideComponent.Frog.Mesh.RemoveMeshFromPlayerOutline(this);
			RideComponent.Frog.FrogDismounted();
			RideComponent.Frog.DisableMovementComponent(RideComponent.Frog);
			Player.RemoveTickPrerequisiteActor(RideComponent.Frog);
			RideComponent.Frog = nullptr;
		}

		if(WasActionStarted(ActionNames::Cancel) && DeactivationParams.DeactivationReason == ECapabilityStatusChangeReason::Natural)
		{
			Player.SetCapabilityActionState(n"ForceJump", EHazeActionState::Active);
		}	

		Player.SetCapabilityActionState(n"Dismount", EHazeActionState::Inactive);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		RideComponent.Frog.CurrentMovementInput = GetAttributeVector2D(AttributeVectorNames::MovementDirection);
		if(Player.Mesh.CanRequestLocomotion())
		{
			FHazeRequestLocomotionData Request;
			Request.AnimationTag = n"GardenFrog";
			Player.RequestLocomotion(Request);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void OnFrogAnimationUpdate(UHazeSkeletalMeshComponentBase Mesh)
	{
		FTransform AttachBoneTransform = Mesh.GetSocketTransform(n"Totem");
		Player.Mesh.SetWorldLocationAndRotation(AttachBoneTransform.Location, AttachBoneTransform.Rotation);
	}
}
