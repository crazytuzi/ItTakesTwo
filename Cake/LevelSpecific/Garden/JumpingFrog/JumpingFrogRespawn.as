import Vino.PlayerHealth.FadedPlayerRespawnEffect;
import Vino.Checkpoints.Checkpoint;
import Vino.Camera.Components.CameraUserComponent;
import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrogPlayerRideComponent;

class UJumpingFrogRespawnEffect : UFadedPlayerRespawnEffect
{
	void TeleportToRespawnLocation(FPlayerRespawnEvent Event) override
	{
		// We dont teleport the player here, instead, we teleport the frog
		auto FrogComponent = UJumpingFrogPlayerRideComponent::Get(Player);
		if(FrogComponent == nullptr)
		{
			Super::TeleportToRespawnLocation(Event);
			return;
		}

		auto Frog = FrogComponent.Frog;
		if(Frog == nullptr)
		{
			Super::TeleportToRespawnLocation(Event);
			return;
		}

		Frog.TeleportActor(
			Location = Event.GetWorldLocation(),
			Rotation = Event.Rotation);

		Frog.SetAnimBoolParam(n"Respawned", true);
		UCameraUserComponent::Get(Player).SetDesiredRotation(Event.Rotation);
	}
}

class AJumpingFrogCheckPoint : ACheckpoint
{
	default RespawnEffect = UJumpingFrogRespawnEffect::StaticClass();
	default RespawnPriority = ECheckpointPriority::High;

	UPROPERTY(EditInstanceOnly)
	TArray<AJumpingFrog> AvailableFrogs;

	bool IsEnabledForPlayer(AHazePlayerCharacter Player) override
	{
		if(!Super::IsEnabledForPlayer(Player))
			return false;

		for(auto Frog : AvailableFrogs)
		{
			if(Frog.MountedPlayer == nullptr || Frog.MountedPlayer != Player)
				return false;
		}

		return true;
	}

	void OnEnabledForPlayer(AHazePlayerCharacter Player) override
	{
		for(auto Frog : AvailableFrogs)
		{
			if(Frog.MountedPlayer != nullptr && Frog.MountedPlayer != Player)
				continue;

			Frog.RespawnTransform = GetPositionForPlayer(Player);
		}
		Super::OnEnabledForPlayer(Player);
	}

	void OnRespawnTriggered(AHazePlayerCharacter Player) override
	{
		Super::OnRespawnTriggered(Player);

		// We are already on a frog
		auto FrogComponent = UJumpingFrogPlayerRideComponent::Get(Player);
		if(FrogComponent != nullptr)
		{
			auto ActiveFrog = FrogComponent.Frog;
			if(ActiveFrog != nullptr)
			{
				ActiveFrog.bDying = false;
				ActiveFrog.FrogMoveComp.StopMovement(true, true);
				ActiveFrog.SetCapabilityActionState(n"AudioFrogRespawn", EHazeActionState::ActiveForOneFrame);
				return;
			}
		}

		for(AJumpingFrog Frog : AvailableFrogs)
		{
			if(Frog.MountedPlayer != nullptr)
				continue;

			Player.TeleportActor(
				Location = Frog.GetActorLocation(),
		 		Rotation = Frog.GetActorRotation()
		 	);

			Frog.MountAnimal(Player);
			return;
		}

		Player.TeleportActor(
			Location = GetActorLocation(),
			Rotation = GetActorRotation()
		);
	}
}