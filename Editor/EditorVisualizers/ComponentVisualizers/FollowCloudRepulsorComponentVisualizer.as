import Cake.LevelSpecific.Music.LevelMechanics.Classic.FollowCloud.FollowCloudRepulsor;

class UFollowCloudRepulsorComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UFollowCloudRepulsorComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		UFollowCloudRepulsorComponent Comp = Cast<UFollowCloudRepulsorComponent>(Component);
		if (!ensure(Comp != nullptr))
			return;

		const FLinearColor Color = FLinearColor(1.f, 0.5f, 0.f);
		FVector Origin = Comp.WorldLocation;
		DrawWireSphere(Origin, Comp.InnerRadius, Color, 5.f, 16);
		DrawWireSphere(Origin, Comp.OuterRadius, FLinearColor::Yellow, 5.f, 16);
		float From = Comp.InnerRadius;
		float To = Comp.OuterRadius - 40.f;
		DrawArrow(Origin + FVector::ForwardVector * From, Origin + FVector::ForwardVector * To, Color, 50, 10.f);  
		DrawArrow(Origin - FVector::ForwardVector * From, Origin - FVector::ForwardVector * To, Color, 50, 10.f);  
		DrawArrow(Origin + FVector::UpVector * From, Origin + FVector::UpVector * To, Color, 50, 10.f);  
		DrawArrow(Origin - FVector::UpVector * From, Origin - FVector::UpVector * To, Color, 50, 10.f);  
		DrawArrow(Origin + FVector::RightVector * From, Origin + FVector::RightVector * To, Color, 50, 10.f);  
		DrawArrow(Origin - FVector::RightVector * From, Origin - FVector::RightVector * To, Color, 50, 10.f);  
	}
} 
