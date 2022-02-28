import Cake.SlotCar.SlotCarActor;
import Cake.SlotCar.SlotCarTrackActor;
import Cake.SlotCar.SlotCarWidget;

class ASlotCarManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent, Attach = "Billboard")
	UTextRenderComponent SlotCarManagerText;
	default SlotCarManagerText.SetRelativeLocation(FVector(0, 0, 50.f));
	default SlotCarManagerText.SetText(FText::FromString("Slot Car Manager"));
	default SlotCarManagerText.SetHorizontalAlignment(EHorizTextAligment::EHTA_Center);
	default SlotCarManagerText.SetVerticalAlignment(EVerticalTextAligment::EVRTA_TextCenter);
	default SlotCarManagerText.SetHiddenInGame(true);

	UPROPERTY(Category = "Manager Settings")
	TArray<ASlotCarTrackActor> SlotCarTracks;
	UPROPERTY(Category = "Manager Settings")
	TSubclassOf<USlotCarTrackWidget> SlotCarTrackWidgetClass;
	USlotCarTrackWidget SlotCarTrackWidget; 
	UPROPERTY()
	TMap<ASlotCarActor, ASlotCarTrackActor> ActiveSlotCars;

	UFUNCTION(NetFunction)
	void AddPlayerToTrack(AHazePlayerCharacter Player, int TrackIndex)
	{
		// // If the track pointer is valid
		// if (SlotCarTracks.IsValidIndex(TrackIndex))
		// {
		// 	//ASlotCarActor SpawnedSlotCar = SlotCarTracks[TrackIndex].AddPlayerCar(Player);
		// 	ActiveSlotCars.Add(SpawnedSlotCar, SlotCarTracks[TrackIndex]);

		// 	// Open UI
		// 	if (SlotCarTracks[TrackIndex].SlotCarsOnTrack.Num() == 1)
		// 	{
		// 		Player.SetViewSize(EHazeViewPointSize::Fullscreen);
		// 		if (SlotCarTrackWidgetClass.IsValid())
		// 		{
		// 			SlotCarTrackWidget = Cast<USlotCarTrackWidget>(Player.AddWidget(SlotCarTrackWidgetClass));
					
		// 			ASlotCarTrackActor Track;
		// 			ActiveSlotCars.Find(SpawnedSlotCar, Track);
		// 			SlotCarTrackWidget.Setup(Track);
		// 			SlotCarTrackWidget.AddPlayerSlotCar(SpawnedSlotCar, Player.Player);
		// 			//SlotCarTrackWidget.AssignPlayerToWidget(SpawnedSlotCar, Player.Player);
		// 		}
		// 	}
		// 	else            
		// 	{
		// 		Player.SetViewSize(EHazeViewPointSize::Hide);
				
		// 		if (SlotCarTrackWidget != nullptr)
		// 			SlotCarTrackWidget.AddPlayerSlotCar(SpawnedSlotCar, Player.Player);      
		// 	}
		// }
	}
}