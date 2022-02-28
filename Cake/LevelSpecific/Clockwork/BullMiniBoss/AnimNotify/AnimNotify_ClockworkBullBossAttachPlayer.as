import Cake.FlyingMachine.Melee.MeleeTags;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBoss;
import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockWorkBullBossPlayerComponent;

// This will attach the player if it collides with the bullimpacts
UCLASS(NotBlueprintable, meta = ("ClockworkBullBossAttachPlayer"))
class UAnimNotify_ClockworkBullBossAttachPlayer : UAnimNotifyState
{
	// If >= 0, the attached time is used, else, the length of the notify is used
	UPROPERTY()
	float AttachedTime = -1;

	// If not NONE, this will only attach when the impact of a crurrent type has happend
	UPROPERTY()
	EBullBossDamageInstigatorType RequiredInstigator = EBullBossDamageInstigatorType::None;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "ClockworkBullBossAttachPlayer";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration)const
	{
		AClockworkBullBoss Bull = Cast<AClockworkBullBoss>(MeshComp.GetOwner());	
		if(Bull != nullptr)
		{
			TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
			for(auto Player : Players)
			{
				auto BossComp = UClockWorkBullBossPlayerComponent::Get(Player);
				if(BossComp != nullptr)
				{
					BossComp.bShouldBeAttachedToBoss = true;
					BossComp.TimeLeftToRelease = AttachedTime >= 0 ? AttachedTime : TotalDuration;
					BossComp.RequiredAttachmentInstigator = RequiredInstigator;
					// if(ForceAttachTo != EBullBossDamageInstigatorType::None && Bull.CurrentTargetPlayer != nullptr)
					// {
					// 	auto BullComp = UClockWorkBullBossPlayerComponent::Get(Bull.CurrentTargetPlayer);
					// 	BullComp.AttachToBull(ForceAttachTo);
					// }				
				}
			}
		}

		return true;
	}


	
	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation)const
	{
		AClockworkBullBoss Bull = Cast<AClockworkBullBoss>(MeshComp.GetOwner());	
		if(Bull != nullptr)
		{
			TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
			for(auto Player : Players)
			{
				auto BossComp = UClockWorkBullBossPlayerComponent::Get(Player);
				if(BossComp != nullptr && BossComp.TimeLeftToRelease <= 0.f)
				{
					BossComp.bShouldBeAttachedToBoss = false;
					BossComp.RequiredAttachmentInstigator = EBullBossDamageInstigatorType::None;
				}
			}
		}

		return true;
	}

};