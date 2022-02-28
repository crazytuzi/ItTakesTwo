
class UMusicJumpToComponent : UActorComponent
{
    bool bJump = false;

	USceneComponent TargetComponent = nullptr;

	FTransform TargetTransform;

	float AdditionalHeight = 160.0f;
}
