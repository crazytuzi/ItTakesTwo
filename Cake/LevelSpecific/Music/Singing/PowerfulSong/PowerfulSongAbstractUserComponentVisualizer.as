import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongAbstractUserComponent;

#if EDITOR

class UPowerfulSongAbstractUserComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPowerfulSongAbstractUserComponent::StaticClass();

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		UPowerfulSongAbstractUserComponent Comp = Cast<UPowerfulSongAbstractUserComponent>(Component);
		if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
		{
			return;
		}

		const float Length = 200.0f;
		const FVector StartLocation = Comp.WorldLocation;

		const FVector RightStartLocation = Comp.RightStartLocation;
		const FVector LeftStartLocation = Comp.LeftStartLocation;
		const FVector UpStartLocation = Comp.UpStartLocation;
		const FVector BottomStartLocation = Comp.BottomStartLocation;

		const FVector RightOffset = Comp.RightOffset;
		const FVector LeftOffset = Comp.LeftOffset;
		const FVector UpOffset = Comp.UpOffset;
		const FVector BottomOffset = Comp.BottomOffset;

		DrawArrow(RightStartLocation, RightStartLocation + (RightOffset * Length), FLinearColor::Green);
		DrawArrow(LeftStartLocation, LeftStartLocation + (LeftOffset * Length), FLinearColor::Green);

		DrawArrow(UpStartLocation, UpStartLocation + (UpOffset * Length), FLinearColor::Blue);
		DrawArrow(BottomStartLocation, BottomStartLocation + (BottomOffset * Length), FLinearColor::Blue);
	
		const float NormalLocationLength = Length * 0.5f;
		const float NormalLength = 30.0f;

		const FVector RightNormalStartLocation = RightStartLocation + (RightOffset * NormalLocationLength);
		const FVector LeftNormalStartLocation = LeftStartLocation + (LeftOffset * NormalLocationLength);
		const FVector UpNormalStartLocation = UpStartLocation + (UpOffset * NormalLocationLength);
		const FVector BottomNormalStartLocation = BottomStartLocation + (BottomOffset * NormalLocationLength);

		DrawArrow(RightNormalStartLocation, RightNormalStartLocation + (Comp.RightNormal * NormalLength), FLinearColor::Red);
		DrawArrow(LeftNormalStartLocation, LeftNormalStartLocation - (Comp.LeftNormal * NormalLength), FLinearColor::Red);
		DrawArrow(UpNormalStartLocation, UpNormalStartLocation + (Comp.UpNormal * NormalLength), FLinearColor::Red);
		DrawArrow(BottomNormalStartLocation, BottomNormalStartLocation - (Comp.BottomNormal * NormalLength), FLinearColor::Red);

		DrawArrow(StartLocation, StartLocation + (Comp.ForwardVector * Comp.PowerfulSongRange), FLinearColor::LucBlue);

	}
}

#endif // EDITOR
