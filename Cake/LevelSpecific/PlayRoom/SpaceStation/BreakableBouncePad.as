import Vino.BouncePad.BouncePad;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;

class ABreakableBouncePad : ABouncePad
{
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent PopEffectComp;
	default PopEffectComp.bAutoActivate = false;

	UPROPERTY()
	bool bAlwaysBreak = false;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PopAudioEvent;

	UFUNCTION()
	void PlayerLandedOnBouncePad(AHazePlayerCharacter Player, FHitResult HitResult) override
	{
		bool bTriggerBounce = true;
		bool bBreak = bAlwaysBreak;
		UCharacterChangeSizeComponent ChangeSizeComp = UCharacterChangeSizeComponent::Get(Player);
		if (ChangeSizeComp != nullptr)
		{
			if (ChangeSizeComp.CurrentSize == ECharacterSize::Large)
			{
				bBreak = true;
				bTriggerBounce = false;
			}
		}

		if (bBreak)
		{
			SetActorEnableCollision(false);
			BouncePadMesh.SetHiddenInGame(true);
			PopEffectComp.Activate(true);
			Player.PlayerHazeAkComp.HazePostEvent(PopAudioEvent);
		}

		if (!bTriggerBounce)
			return;

		Super::PlayerLandedOnBouncePad(Player, HitResult);
	}
}