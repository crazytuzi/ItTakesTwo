import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.PlayRoom.SpaceStation.SurveillanceSatelliteDishSoundWidget;
import Cake.LevelSpecific.PlayRoom.SpaceStation.SurveillanceSatelliteDishFocusPoint;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureArcadeScreenLever;
import Cake.LevelSpecific.PlayRoom.VOBanks.SpacestationVOBank;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeStatics;

class ASurveillanceSatelliteDish : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BaseRoot;

	UPROPERTY(DefaultComponent, Attach = BaseRoot)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent, Attach = BaseRoot)
	USceneComponent StandRoot;

	UPROPERTY(DefaultComponent, Attach = StandRoot)
	UStaticMeshComponent StandMesh;

	UPROPERTY(DefaultComponent, Attach = StandRoot)
	USceneComponent DishRoot;

	UPROPERTY(DefaultComponent, Attach = DishRoot)
	UStaticMeshComponent DishMesh;

	UPROPERTY(DefaultComponent, Attach = DishRoot)
	UHazeCameraComponent CamComp;

	UPROPERTY(DefaultComponent, Attach = StandRoot)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent, Attach = StandRoot)
	UHazeSkeletalMeshComponentBase Joystick;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncPitchComp;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncRotationComponent SyncYawComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> RequiredCapability;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<USurveillanceSatelliteDishSoundWidget> WidgetClass;

	UPROPERTY(EditDefaultsOnly)
	UCurveFloat SoundAlphaCurve;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlaySurveillanceSatelliteDishAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopSurveillanceSatelliteDishAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlaySurveillanceSatelliteDishMovementAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopSurveillanceSatelliteDishMovementAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlaySurveillanceSatelliteDishVOAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopSurveillanceSatelliteDishVOAudioEvent;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureArcadeScreenLever MayFeature;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureArcadeScreenLever CodyFeature;

	UPROPERTY(EditDefaultsOnly)
	USpacestationVOBank VOBank;

	bool bActive = false;

	TArray<ASurveillanceSatelliteDishFocusPoint> FocusPoints;
	TArray<ASurveillanceSatelliteDishFocusPoint> FullyListenedFocusPoints;

	AHazePlayerCharacter InteractingPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Capability::AddPlayerCapabilityRequest(RequiredCapability);

		InteractionComp.OnActivated.AddUFunction(this, n"InteractionActivated");

		TArray<AActor> Actors;
		Gameplay::GetAllActorsOfClass(ASurveillanceSatelliteDishFocusPoint::StaticClass(), Actors);
		for (AActor Actor : Actors)
		{
			ASurveillanceSatelliteDishFocusPoint FocusPoint = Cast<ASurveillanceSatelliteDishFocusPoint>(Actor);
			if (FocusPoint != nullptr)
				FocusPoints.Add(FocusPoint);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(RequiredCapability);
	}

	UFUNCTION(NotBlueprintCallable)
	void InteractionActivated(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		InteractingPlayer = Player;
		InteractionComp.Disable(n"Used");
		Player.SetCapabilityAttributeObject(n"SatelliteDish", this);
		Player.SetCapabilityActionState(n"Surveillance", EHazeActionState::Active);

		if (Player.IsCody())
			ForceCodyMediumSize();
		
		bActive = true;
	}

	void InteractionCancelled(AHazePlayerCharacter Player)
	{
		InteractionComp.EnableAfterFullSyncPoint(n"Used");
		bActive = false;
		InteractingPlayer = nullptr;
	}
	
	UFUNCTION(NetFunction)
	void NetSetFocusPointFullyListened(ASurveillanceSatelliteDishFocusPoint FocusPoint)
	{
		if (InteractingPlayer != nullptr)
		{
			FName ReplyEvent = InteractingPlayer.IsMay() ? FocusPoint.MayReplyEvent : FocusPoint.CodyReplyEvent;
			if (ReplyEvent != n"None")
				VOBank.PlayFoghornVOBankEvent(ReplyEvent);
		}

		FocusPoint.SetFocusPointFullyListened();
		FullyListenedFocusPoints.AddUnique(FocusPoint);
		if (FullyListenedFocusPoints.Num() >= FocusPoints.Num())
		{
			for (AHazePlayerCharacter Player : Game::GetPlayers())
				Online::UnlockAchievement(Player, n"BigBrother");
		}
	}
}