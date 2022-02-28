import Vino.Camera.Capabilities.LookAtFocusPointCapability;

enum ECameraDebugDisplayType
{
	View,
	Owner,
	Collision,
	SpringArmPivot,
	SpringArmLag,
	AnimationInspect,
	Blend,
	HazeDebugBool,
	CurrentCamera,
	BlendOutBehaviour,
	MAX, // Note that we can only have 64 flags
}

namespace FCameraTags
{
	const FName DebugCamera	= n"DebugCameraIsActive";
}

UFUNCTION()
void LookAtFocusPoint(AHazePlayerCharacter Player, FLookatFocusPointData Settings)
{
	ULookatFocusPointComponent::GetOrCreate(Player).Settings = Settings;
	Player.SetCapabilityActionState(n"LookAtFocusPoint", EHazeActionState::Active);
}

UFUNCTION()
void LookAtFocusPointWBlocklist(AHazePlayerCharacter Player, FLookatFocusPointData Settings, TArray<FName> BlockedCapabilities)
{
	ULookatFocusPointComponent::GetOrCreate(Player).Settings = Settings;
	ULookatFocusPointComponent::GetOrCreate(Player).Blocklist = BlockedCapabilities;
	Player.SetCapabilityActionState(n"LookAtFocusPoint", EHazeActionState::Active);
}

UFUNCTION()
void StopLookatFocusPoint(AHazePlayerCharacter Player)
{
	Player.SetCapabilityActionState(n"StopLookAtFocusPoint", EHazeActionState::Active);
}

UFUNCTION()
void CopyCameraTransformToClipboard(AHazePlayerCharacter Player)
{
	if (Player == nullptr)
		return;

	FTransform CamTransform = Player.GetPlayerViewTransform();
	FString CamTransformDesc = CamTransform.ToString();
	Editor::CopyToClipBoard(CamTransformDesc);
	PrintScaled("Copy " + Player.Name + " camera transform to clipboard: " + CamTransformDesc, 5.f, Scale = 2.f);
}