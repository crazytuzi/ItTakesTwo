import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.SnowGlobe.Sunchair.SunChairPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.VOBanks.SnowGlobeTownVOBank;
import Peanuts.Foghorn.FoghornStatics;

event void FOnPlayerLeft(AHazePlayerCharacter Player);

class ASunChairInteraction : AHazeActor
{
	UPROPERTY(DefaultComponent, Attach = RootComponent)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(Category = "CapabilitySheet")
	UHazeCapabilitySheet CapabilitySheet;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	UInteractionComponent InteractionComp;

	AHazePlayerCharacter PlayerSitting;

	UPROPERTY()
	USnowGlobeTownVOBank VOBank;

	FOnPlayerLeft OnPlayerLeft;
	
	FName MayVO = n"FoghornDBSnowGlobeTownSunchairsGenericMay";
	FName CodyVO = n"FoghornDBSnowGlobeTownSunchairsGenericCody";

	float CurrentTimeToPlay;
	float DefaultTimeToPlay = 1.f;

	bool bCanPlayVO = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnActivated.AddUFunction(this, n"ActivatedInteraction");
	}

	UFUNCTION()
	void ActivatedInteraction(UInteractionComponent InputInteractComp, AHazePlayerCharacter Player)
	{
		PlayerSitting = Player;
		Player.AddCapabilitySheet(CapabilitySheet);
		USunChairPlayerComponent PlayerComp = USunChairPlayerComponent::Get(Player);
		PlayerComp.OnPlayerCancelChairEvent.AddUFunction(this, n"RemoveSunChairCapabilities");
		PlayerComp.InteractionComp = InputInteractComp;
		PlayerComp.InteractionComp.Disable(n"Sunchair Interactions");

		CurrentTimeToPlay = DefaultTimeToPlay;

		bCanPlayVO = true;
	}

	UFUNCTION()
	void RemoveSunChairCapabilities(AHazePlayerCharacter Player)
	{
		USunChairPlayerComponent PlayerComp = USunChairPlayerComponent::Get(Player);
		PlayerComp.InteractionComp.Enable(n"Sunchair Interactions");
		Player.RemoveCapabilitySheet(CapabilitySheet);
		OnPlayerLeft.Broadcast(Player);
	}
}