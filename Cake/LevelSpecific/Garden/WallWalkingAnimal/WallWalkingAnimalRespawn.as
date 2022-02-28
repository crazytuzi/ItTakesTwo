import Vino.PlayerHealth.FadedPlayerRespawnEffect;
import Vino.Checkpoints.Checkpoint;
import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimal;
import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimalComponent;

class USpiderRespawnEffect : UFadedPlayerRespawnEffect
{
	void TeleportToRespawnLocation(FPlayerRespawnEvent Event)
	{
		// We dont teleport the player here, instead, we teleport the frog
		auto SpiderComponent = UWallWalkingAnimalComponent::Get(Player);
		if(SpiderComponent == nullptr)
		{
			Super::TeleportToRespawnLocation(Event);
			return;
		}

		auto Spider = SpiderComponent.CurrentAnimal;
		if(Spider == nullptr)
		{
			Super::TeleportToRespawnLocation(Event);
			return;
		}

		Spider.TeleportActor( Event.GetWorldLocation(), Event.Rotation);
		UCameraUserComponent::Get(Player).SetDesiredRotation(Event.Rotation);
	}
};


class ASpiderCheckPoint : ACheckpoint
{
	default RespawnEffect = USpiderRespawnEffect::StaticClass();
	default RespawnPriority = ECheckpointPriority::High;
	default SecondPosition =  FTransform(FVector(0, 300, 0));

	UPROPERTY(EditDefaultsOnly)
	USkeletalMesh CustomMesh;

	UPROPERTY(EditInstanceOnly)
	AWallWalkingAnimal CodySpider;
	
	UPROPERTY(EditInstanceOnly)
	AWallWalkingAnimal MaySpider;	

	void CreateForPlayer(EHazePlayer Player, const FTransform& RelativeTransform) override
	{
		Super::CreateForPlayer(Player, RelativeTransform);

#if EDITOR
		if(Player == EHazePlayer::May && MaySpider != nullptr || (MaySpider == nullptr && CodySpider == nullptr))
			CreatePlayerEditorVisualizer(Root, Player, RelativeTransform, CustomMesh);

		if(Player == EHazePlayer::Cody && CodySpider != nullptr || (MaySpider == nullptr && CodySpider == nullptr))
			CreatePlayerEditorVisualizer(Root, Player, RelativeTransform, CustomMesh);
#endif

	}

	void OnRespawnTriggered(AHazePlayerCharacter Player) override
	{
		Super::OnRespawnTriggered(Player);


		// We are already on a spider
		auto SpiderComponent = UWallWalkingAnimalComponent::Get(Player);
		if(SpiderComponent != nullptr)
		{
			auto Spider = SpiderComponent.CurrentAnimal;
			if(Spider != nullptr)
			{
				Spider.SetCapabilityActionState(n"AudioSpiderRespawn", EHazeActionState::ActiveForOneFrame);
				return;
			}
		}

		if(Player.IsMay())
		{
			if(MaySpider != nullptr)
			{
				MaySpider.SetCapabilityActionState(n"AudioSpiderRespawn", EHazeActionState::ActiveForOneFrame);
				MaySpider.TeleportActor(Player.GetActorLocation(), Player.GetActorRotation());
				MaySpider.MountAnimal(Player);
			}
		}
		else
		{
			if(CodySpider != nullptr)
			{
				CodySpider.SetCapabilityActionState(n"AudioSpiderRespawn", EHazeActionState::ActiveForOneFrame);
				CodySpider.TeleportActor(Player.GetActorLocation(), Player.GetActorRotation());
				CodySpider.MountAnimal(Player);
			}
		}
	}

	UFUNCTION()
	protected void TriggerCheckpoint(AHazePlayerCharacter Player)
	{
		auto SpiderComponent = UWallWalkingAnimalComponent::Get(Player);
		if(SpiderComponent != nullptr)
			return;

		auto Spider = SpiderComponent.CurrentAnimal;
		if(Spider == nullptr)
		{
			if(Player.IsMay())
			{
				if(MaySpider != nullptr)
				{
					MaySpider.MountAnimal(Player);
					Spider = SpiderComponent.CurrentAnimal;
				}
			}
			else
			{
				if(CodySpider != nullptr)
				{
					CodySpider.MountAnimal(Player);
					Spider = SpiderComponent.CurrentAnimal;
				}
			}
		}

		if(Spider != nullptr)
		{
			const FTransform TransformForPlayer = GetPositionForPlayer(Player);
			Spider.TeleportActor(TransformForPlayer.GetLocation(), TransformForPlayer.Rotator());
			UCameraUserComponent::Get(Player).SetDesiredRotation(TransformForPlayer.Rotator());
		}
	} 
}