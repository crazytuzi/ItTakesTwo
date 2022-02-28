float GetNumberOfSegmentsBasedOnDistance(float Distance, float MaxDistance = 5000, float Min = 6, float Max = 100)
{
	float Distance01 = FMath::Clamp((MaxDistance - Distance) / MaxDistance, 0.0f, 1.0f);
	return FMath::Lerp(Min, Max, Distance01);
}

float GetNumberOfSegmentsBasedOnDistance(AActor Owner, float MaxDistance = 5000, float Min = 6, float Max = 100)
{
	float Distance = Editor::GetEditorViewLocation().Distance(Owner.GetActorLocation());
	return GetNumberOfSegmentsBasedOnDistance(Distance, MaxDistance, Min, Max);
}

bool ShouldDrawDebugLines(AActor Owner, float MaxDistance = 5000)
{
	float Distance = Editor::GetEditorViewLocation().Distance(Owner.GetActorLocation());
	return Distance < MaxDistance;
}

void DrawDebugActorRotation(AActor Actor, float LineLength = 200.f, float Duration = 0.f)
{
	System::DrawDebugLine(Actor.ActorLocation, Actor.ActorLocation + Actor.ActorUpVector * LineLength, FLinearColor::Blue, Duration);
	System::DrawDebugLine(Actor.ActorLocation, Actor.ActorLocation + Actor.ActorForwardVector * LineLength, FLinearColor::Red, Duration);
	System::DrawDebugLine(Actor.ActorLocation, Actor.ActorLocation + Actor.ActorRightVector * LineLength, FLinearColor::Green, Duration);
}