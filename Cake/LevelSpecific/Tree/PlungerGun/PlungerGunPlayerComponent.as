import Cake.LevelSpecific.Tree.PlungerGun.PlungerGun;

class UPlungerGunPlayerComponent : UActorComponent
{
	UPROPERTY(Category = "Animations")
	TPerPlayer<UAnimSequence> EnterAnim;

	UPROPERTY(Category = "Animations")
	TPerPlayer<UAnimSequence> MHAnim;

	UPROPERTY()
	UForceFeedbackEffect ShootForceFeedback;

	APlungerGun Gun;
	UPlungerGunCrosshairWidget Widget;
	bool bNaturalExit = false;

	void ExitGun()
	{
		bNaturalExit = true;

		auto HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.RemoveCapabilitySheet(Gun.PlayerSheet, Gun);
		Gun = nullptr;

		bNaturalExit = false;
	}
}

void PlungerGunPlayerEnter(AHazePlayerCharacter Player, APlungerGun Gun)
{
	Player.AddCapabilitySheet(Gun.PlayerSheet, EHazeCapabilitySheetPriority::Interaction, Gun);

	auto PlayerComp = UPlungerGunPlayerComponent::Get(Player);
	PlayerComp.Gun = Gun;
}